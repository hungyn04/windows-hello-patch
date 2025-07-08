// CameraService.cs
using System;
using System.Diagnostics;
using System.Linq;
using System.Management;
using System.Runtime.InteropServices;
using System.ServiceProcess;

namespace HelloPatchService
{
    public class CameraService : ServiceBase
    {
        private const string SERVICE_NAME = "CameraControlService";

        // SetupAPI constants
        private const int DIGCF_PRESENT       = 0x00000002;
        private const int DIGCF_ALLCLASSES    = 0x00000020;
        private const int DICS_ENABLE         = 1;
        private const int DICS_DISABLE        = 2;
        private const int DICS_FLAG_GLOBAL    = 1;
        private const int DIF_PROPERTYCHANGE  = 0x12;

        public CameraService()
        {
            ServiceName                 = SERVICE_NAME;
            CanHandleSessionChangeEvent = true;
            CanStop                     = true;
        }

        public static void Main()
        {
            ServiceBase.Run(new CameraService());
        }

        protected override void OnStart(string[] args)
        {
            EventLog.WriteEntry(SERVICE_NAME, "Service starting", EventLogEntryType.Information);
        }

        protected override void OnStop()
        {
            EventLog.WriteEntry(SERVICE_NAME, "Service stopped", EventLogEntryType.Information);
        }

        protected override void OnSessionChange(SessionChangeDescription change)
        {
            base.OnSessionChange(change);

            var (instanceId, friendlyName) = GetFrontCamera();
            if (instanceId == null)
            {
                EventLog.WriteEntry(SERVICE_NAME,
                    "No front-facing camera found on session change",
                    EventLogEntryType.Warning);
                return;
            }

            switch (change.Reason)
            {
                case SessionChangeReason.SessionLock:
                    EventLog.WriteEntry(SERVICE_NAME,
                        $"Session locked – disabling {friendlyName}",
                        EventLogEntryType.Information);
                    ChangeDeviceState(instanceId, DICS_DISABLE);
                    break;

                case SessionChangeReason.SessionUnlock:
                    EventLog.WriteEntry(SERVICE_NAME,
                        $"Session unlocked – enabling {friendlyName}",
                        EventLogEntryType.Information);
                    ChangeDeviceState(instanceId, DICS_ENABLE);
                    break;
            }
        }

        private (string? InstanceId, string? FriendlyName) GetFrontCamera()
        {
            try
            {
                using var searcher = new ManagementObjectSearcher(
                    "SELECT PNPClass, Name, DeviceID FROM Win32_PnPEntity WHERE PNPClass='Image' AND Status='OK'");
                foreach (ManagementObject dev in searcher.Get())
                {
                    var name = (string?)dev["Name"];
                    var id   = (string?)dev["DeviceID"];
                    if (name != null && id != null
                        && (name.Contains("Front", StringComparison.OrdinalIgnoreCase)
                            || name.Contains("Integrated", StringComparison.OrdinalIgnoreCase))
                        && !name.Contains("IR", StringComparison.OrdinalIgnoreCase)
                        && !name.Contains("Infrared", StringComparison.OrdinalIgnoreCase)
                        && !name.Contains("Hello", StringComparison.OrdinalIgnoreCase))
                    {
                        return (id, name);
                    }
                }
            }
            catch (Exception ex)
            {
                EventLog.WriteEntry(SERVICE_NAME,
                    $"Error enumerating cameras: {ex.Message}",
                    EventLogEntryType.Error);
            }

            return (null, null);
        }

        private void ChangeDeviceState(string instanceId, int newState)
        {
            // Copy into a mutable local so we can pass by ref
            var classGuid = Guid.Empty; 

            // Acquire all PnP devices, then open the one we want
            IntPtr devInfo = SetupDiGetClassDevs(
                ref classGuid,
                IntPtr.Zero,
                IntPtr.Zero,
                DIGCF_PRESENT | DIGCF_ALLCLASSES);
            if (devInfo == IntPtr.Zero)
            {
                EventLog.WriteEntry(SERVICE_NAME,
                    $"SetupDiGetClassDevs failed (err={Marshal.GetLastWin32Error()})",
                    EventLogEntryType.Error);
                return;
            }

            try
            {
                var devInfoData = new SP_DEVINFO_DATA { cbSize = Marshal.SizeOf<SP_DEVINFO_DATA>() };
                if (!SetupDiOpenDeviceInfo(devInfo, instanceId, IntPtr.Zero, 0, ref devInfoData))
                {
                    EventLog.WriteEntry(SERVICE_NAME,
                        $"SetupDiOpenDeviceInfo failed for {instanceId} (err={Marshal.GetLastWin32Error()})",
                        EventLogEntryType.Error);
                    return;
                }

                var parms = new SP_PROPCHANGE_PARAMS
                {
                    Size        = Marshal.SizeOf<SP_PROPCHANGE_PARAMS>(),
                    StateChange = newState,
                    Scope       = DICS_FLAG_GLOBAL,
                    HwProfile   = 0
                };

                bool ok = SetupDiSetClassInstallParams(devInfo, ref devInfoData, ref parms, parms.Size);
                if (!ok)
                {
                    EventLog.WriteEntry(SERVICE_NAME,
                        $"SetClassInstallParams failed (err={Marshal.GetLastWin32Error()})",
                        EventLogEntryType.Error);
                }

                ok = SetupDiCallClassInstaller(DIF_PROPERTYCHANGE, devInfo, ref devInfoData);
                if (!ok)
                {
                    EventLog.WriteEntry(SERVICE_NAME,
                        $"CallClassInstaller failed (err={Marshal.GetLastWin32Error()})",
                        EventLogEntryType.Error);
                }
            }
            finally
            {
                SetupDiDestroyDeviceInfoList(devInfo);
            }
        }

        // P/Invoke structs and methods

        [StructLayout(LayoutKind.Sequential)]
        private struct SP_PROPCHANGE_PARAMS
        {
            public int Size, StateChange, Scope, HwProfile;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        private struct SP_DEVINFO_DATA
        {
            public int   cbSize;
            public Guid  ClassGuid;
            public int   DevInst;
            public IntPtr Reserved;
        }

        [DllImport("setupapi.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern IntPtr SetupDiGetClassDevs(
            ref Guid ClassGuid, IntPtr Enumerator, IntPtr hwndParent, int Flags);

        [DllImport("setupapi.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool SetupDiOpenDeviceInfo(
            IntPtr DeviceInfoSet, string DeviceInstanceId, IntPtr hwndParent, int Flags, ref SP_DEVINFO_DATA DeviceInfoData);

        [DllImport("setupapi.dll", SetLastError = true)]
        private static extern bool SetupDiSetClassInstallParams(
            IntPtr DeviceInfoSet, ref SP_DEVINFO_DATA DeviceInfoData,
            ref SP_PROPCHANGE_PARAMS ClassInstallParams, int ClassInstallParamsSize);

        [DllImport("setupapi.dll", SetLastError = true)]
        private static extern bool SetupDiCallClassInstaller(
            int InstallFunction, IntPtr DeviceInfoSet, ref SP_DEVINFO_DATA DeviceInfoData);

        [DllImport("setupapi.dll", SetLastError = true)]
        private static extern bool SetupDiDestroyDeviceInfoList(IntPtr DeviceInfoSet);
    }
}
