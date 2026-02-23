-- server.lua
local http_server = require "http.server"
local http_headers = require "http.headers"
local uuid = require "uuid"

uuid.seed() -- for unique IDs

-- Function to run catnapdumper
local function run_catnapdumper(input_code)
    local id = uuid()
    local input_file = "/tmp/input_" .. id .. ".lua"
    local output_file = "/tmp/output_" .. id .. ".lua"

    -- Write input Lua code to file
    local f = io.open(input_file, "w")
    f:write(input_code)
    f:close()

    -- Run catnapdumper.lua
    local cmd = string.format("lua catnapdumper.lua.txt %s %s", input_file, output_file)
    local ok, exit, code = os.execute(cmd)
    if exit ~= 0 then
        return nil, "Error running catnapdumper"
    end

    -- Read output
    local of = io.open(output_file, "r")
    if not of then return nil, "Output file missing" end
    local output_code = of:read("*all")
    of:close()

    -- Cleanup temp files
    os.remove(input_file)
    os.remove(output_file)

    -- Wrap output in CODE: "..."
    output_code = 'CODE: "' .. output_code:gsub('"', '\\"') .. '"'

    return output_code
end

-- Start HTTP server
local server = http_server.listen {
    host = "0.0.0.0",
    port = tonumber(os.getenv("PORT")) or 10000,
    onstream = function(server, stream)
        local req_headers = stream:get_headers()
        local method = req_headers:get(":method")

        if method ~= "POST" then
            -- Only POST allowed
            local h = http_headers.new()
            h:append(":status", "405")
            stream:write_headers(h, false)
            stream:write_body("Only POST requests allowed")
            return
        end

        -- Read body (Lua code)
        local body = stream:get_body_as_string()
        local output, err = run_catnapdumper(body)

        -- Respond with output or error
        local resp_headers = http_headers.new()
        resp_headers:append(":status", output and "200" or "500")
        resp_headers:append("content-type", "text/plain; charset=utf-8")
        stream:write_headers(resp_headers, false)
        stream:write_body(output or err)
    end
}

print("API server running on http://0.0.0.0:10000")
assert(server:loop())
