import "Locksmith.LocksmithInfoWindow"

locks = Turbine.ShellCommand()
function locks:Execute(_, str)
    if SessionVariables["settings"]["showWindow"] then
        return
    end
    SessionVariables["settings"]["showWindow"] = true
    LocksmithInfoWindow()
end
Turbine.Shell.AddCommand("locks", locks)

