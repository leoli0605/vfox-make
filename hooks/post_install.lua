local util = require("util")

--- Extension point, called after PreInstall, can perform additional operations,
--- such as file operations for the SDK installation directory or compile source code
--- Currently can be left unimplemented!
function PLUGIN:PostInstall(ctx)
    --- ctx.rootPath SDK installation directory
    local rootPath = ctx.rootPath
    local sdkInfo = ctx.sdkInfo['make']
    local path = sdkInfo.path
    local version = sdkInfo.version
    local name = sdkInfo.name
    local note = sdkInfo.note

    util:pixi_install(path, version)
end
