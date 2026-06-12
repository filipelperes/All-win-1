$settingsMenu = [PSCustomObject]@{
    Description = "Settings"
    Label       = "Settings"
    Submenu     = @(
        [PSCustomObject]@{ Label = "Open Additional Mouse Settings"; Action = { Start-Process "control.exe" -ArgumentList "main.cpl" -Verb RunAs } }
        [PSCustomObject]@{ Label = "Open Additional Power Settings"; Action = { Start-Process "control.exe" -ArgumentList "powercfg.cpl" -Verb RunAs } }
        [PSCustomObject]@{ Label = "Open Background Settings"; Action = { Start-Process "ms-settings:personalization-background" } }
        [PSCustomObject]@{ Label = "Open Colors Settings"; Action = { Start-Process "ms-settings:colors" } }
        [PSCustomObject]@{ Label = "Open Display Settings"; Action = { Start-Process "ms-settings:display" } }
        [PSCustomObject]@{ Label = "Open Environment Variables Settings"; Action = { Start-Process "rundll32.exe" -ArgumentList "sysdm.cpl,EditEnvironmentVariables" -Verb RunAs } }
        [PSCustomObject]@{ Label = "Open Lockscreen Settings"; Action = { Start-Process "ms-settings:lockscreen" } }
        [PSCustomObject]@{ Label = "Open Mouse Settings"; Action = { Start-Process "ms-settings:mousetouchpad" } }
        [PSCustomObject]@{ Label = "Open Multitasking Settings"; Action = { Start-Process "ms-settings:multitasking" } }
        [PSCustomObject]@{ Label = "Open Optional Features Settings (Advanced Users)"; Action = { Start-Process "ms-settings:optionalfeatures" } }
        [PSCustomObject]@{ Label = "Open Performance Settings"; Action = { SystemPropertiesPerformance -Verb RunAs } }
        [PSCustomObject]@{ Label = "Open Power Settings"; Action = { Start-Process "ms-settings:powersleep" } }
        [PSCustomObject]@{ Label = "Open Start Menu Settings"; Action = { Start-Process "ms-settings:personalization-start" } }
        [PSCustomObject]@{ Label = "Open System Properties Settings"; Action = { SystemPropertiesAdvanced -Verb RunAs } }
        [PSCustomObject]@{ Label = "Open Taskbar Settings"; Action = { Start-Process "ms-settings:taskbar" } }
        [PSCustomObject]@{ Label = "Open Windows Features (Enable/Disable)"; Action = { Start-Process "optionalfeatures.exe" } }
    )
}
