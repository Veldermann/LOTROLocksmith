
locks = Turbine.ShellCommand()
function locks:Execute(_, str)
    if LocksmithInfoWindow:IsVisible() then
        return
    end
    LocksmithInfoWindow:ShowWindow()
end
Turbine.Shell.AddCommand("locks", locks)

