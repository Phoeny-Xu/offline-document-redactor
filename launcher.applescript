on run
    set appPath to POSIX path of (path to me)
    set configPath to appPath & "Contents/Resources/contract-desensitizer-path.txt"
    set skillDir to do shell script "/bin/cat " & quoted form of configPath
    set scriptsPath to skillDir & "/scripts/"
    set launcherPath to scriptsPath & "launcher/start.py"
    set venvPython to scriptsPath & ".venv/bin/python"
    try
        set hasVenv to do shell script "/usr/bin/test -x " & quoted form of venvPython & " && printf yes || printf no"
        if hasVenv is "yes" then
            set pythonCommand to quoted form of venvPython
        else
            set pythonCommand to "/usr/bin/env python3"
        end if
        do shell script pythonCommand & " " & quoted form of launcherPath
    on error errorMessage
        display alert "法律文书脱敏助手启动失败" message errorMessage as critical
    end try
end run
