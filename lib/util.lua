local util = {}

local http = require("http")
local json = require("json")

local TOOL_NAME = "make"

function util:fetch_versions()
    local resp, err = http.get({
        url = "https://raw.githubusercontent.com/leoli0605/vfox-make/main/versions.json"
    })
    if err ~= nil or resp.status_code ~= 200 then
        return {}
    end
    local body = json.decode(resp.body)
    local versions = {}
    for _, v in pairs(body["versions"]) do
        table.insert(versions, v)
    end
    table.sort(versions, function(a, b)
        return a > b
    end)
    return versions
end

function util:fetch_available()
    local versions = self:fetch_versions()
    local result = {}
    for i, v in ipairs(versions) do
        table.insert(result, {
            version = v,
            note = i == 1 and "latest" or ""
        })
    end
    return result
end

function util:has_value(table, value)
    for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end

    return false
end

function util:get_info(version)
    local versions = self:fetch_versions()
    local file

    if version == "latest" then
        version = versions[1]
    end
    if not self:has_value(versions, version) then
        print("Unsupported version: " .. version)
        os.exit(1)
    end
    file = self:generate_pixi(RUNTIME.osType, RUNTIME.archType)

    return {
        url = file,
        version = version
    }
end

function util:generate_pixi(osType, archType)
    local file
    local githubURL = os.getenv("GITHUB_URL") or "https://github.com/"
    local releaseURL = githubURL:gsub("/$", "") .. "/prefix-dev/pixi/releases/"

    if archType == "arm64" then
        archType = "aarch64"
    elseif archType == "amd64" then
        archType = "x86_64"
    else
        print("Unsupported architecture: " .. archType)
        os.exit(1)
    end
    if osType == "darwin" then
        file = "pixi-" .. archType .. "-apple-darwin.tar.gz"
    elseif osType == "linux" then
        file = "pixi-" .. archType .. "-unknown-linux-musl.tar.gz"
    elseif osType == "windows" and archType == "x86_64" then
        file = "pixi-" .. archType .. "-pc-windows-msvc.zip"
    else
        print("Unsupported environment: " .. osType .. "-" .. archType)
        os.exit(1)
    end
    file = releaseURL .. "latest/download/" .. file

    return file
end

function util:pixi_install(path, version)
    local condaForge = os.getenv("Conda_Forge") or "conda-forge"
    local noStdout = RUNTIME.osType == "windows" and " > nul" or " > /dev/null"
    local pixi = RUNTIME.osType == "windows" and path .. "\\pixi.exe" or path .. "/pixi"
    local command = pixi .. " global install -qc " .. condaForge .. " " .. TOOL_NAME .. "=" .. version

    os.setenv("PIXI_HOME", path)
    local status = os.execute(command .. noStdout)
    if status ~= 0 then
        print("Failed to execute command: " .. command)
        os.exit(1)
    end
    os.remove(pixi)
end

return util
