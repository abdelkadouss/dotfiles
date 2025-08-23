-- The get_version function you provided (slightly modified for clarity)
local get_version = function(input)
  local curl_handle = io.popen('curl -s "https://api.github.com/repos/' .. input .. '/releases/latest"')
  if curl_handle then
    local response = curl_handle:read("*a")
    curl_handle:close()

    -- Simple string extraction from JSON
    local tag = response:match('"tag_name"%s*:%s*"([^"]+)"')
    if tag then
      if tag:find("%.") then -- if contains dot
        if tag:sub(1, 1) == "v" then
          tag = tag:sub(2)
        end
        return tag
      end
    end
  end

  -- Method 2: Use git tags if available (for development versions)
  local git_handle = io.popen('git ls-remote --tags "https://github.com/' .. input .. '.git" 2>/dev/null')
  if git_handle then
    local tags_output = git_handle:read("*a")
    git_handle:close()

    -- Find the latest tag
    local latest_tag
    for line in tags_output:gmatch("[^\r\n]+") do
      local tag = line:match("refs/tags/(v?%d+%.%d+%.%d+)$") or
          line:match("refs/tags/(v?%d+%.%d+)$")
      if tag then
        if tag:sub(1, 1) == "v" then
          tag = tag:sub(2)
        end
        latest_tag = tag
      end
    end
    if latest_tag then
      return latest_tag
    end
  end

  return "x.x.x" -- fallback
end

local function install(pkg)
  -- Set environment variables
  local env = {
    GOPATH = os.getenv("PWD") or ".", -- Current directory
    GOPROXY = "https://proxy.golang.org,direct",
    GOSUMDB = "sum.golang.org"
  }

  -- Save original environment
  local original_env = {}
  for var, value in pairs(env) do
    original_env[var] = os.getenv(var)
    os.setenv(var, value)
  end

  -- Run go install
  local handle = io.popen("go install " .. pkg .. " 2>&1")
  if not handle then
    return {
      error = "Failed to run go install command"
    }
  end
  local result = handle:read("*a")
  handle:close()

  -- Print the result
  print(result)

  -- Restore original environment
  for var, _ in pairs(env) do
    if original_env[var] then
      os.setenv(var, original_env[var])
    else
      os.setenv(var, nil) -- Unset if it wasn't set before
    end
  end

  -- Parse package URL to get version info
  local function parse_url_path(url)
    -- Remove protocol prefix if present
    local clean_url = url:gsub("^https?://", "")

    -- Split into parts
    local parts = {}
    for part in clean_url:gmatch("[^/]+") do
      table.insert(parts, part)
    end

    -- Remove the last part (package name)
    if #parts > 0 then
      table.remove(parts)
    end

    -- Join remaining parts
    return table.concat(parts, "/")
  end

  local pkg_url_path = parse_url_path("http://" .. pkg)

  -- Keep going up directories until we have a reasonable path
  while pkg_url_path:match("/") and #pkg_url_path:gsub("[^/]", "") > 2 do
    pkg_url_path = pkg_url_path:match("^(.*)/[^/]*$") or pkg_url_path
  end

  -- Construct package URL for version checking
  local function get_host_from_url(url)
    return url:match("^https?://([^/]+)") or ""
  end

  local function get_base_name(url)
    return url:match("/([^/]+)$") or url:match("([^/]+)$")
  end

  local host = get_host_from_url("http://" .. pkg)
  local base_name = get_base_name("http://" .. pkg)
  local pkg_url = host .. "/" .. pkg_url_path .. "/" .. base_name

  -- Get version using the provided get_version function
  local version = get_version() or "x.x.x"

  -- Find the binary file in ./bin directory
  local bin_path = nil
  local bin_dir = "./bin"
  local handle = io.popen("ls " .. bin_dir .. " 2>/dev/null")
  if handle then
    for file in handle:lines() do
      local file_path = bin_dir .. "/" .. file
      local file_handle = io.popen("test -f " .. file_path .. " && echo file || echo other")
      if not file_handle then
        return {
          error = "Failed to check if " .. file_path .. " is a file"
        }
      end
      local file_type = file_handle:read("*a"):gsub("%s+", "")
      file_handle:close()

      if file_type == "file" then
        bin_path = file_path
        break
      end
    end
    handle:close()
  end

  -- Return result as JSON-like table
  return {
    version = version,
    path = bin_path
  }
end

return { install = install }
