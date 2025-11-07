local install = function(input, opts)
  -- Create output directory
  os.execute("mkdir -p out/bin")

  -- Get current directory
  local current_dir = io.popen("pwd"):read("*l")
  local gopath = current_dir .. "/out"
  local gobin = gopath .. "/bin"

  local cmd = { "go", "install" }

  -- Handle different installation sources
  if opts.git then
    table.insert(cmd, input)
    if opts.version then
      table.insert(cmd, "@" .. opts.version)
    end
  else
    table.insert(cmd, input)
    if opts.version then
      table.insert(cmd, "@" .. opts.version)
    end
  end

  -- Run the installation command
  local full_cmd = table.concat(cmd, " ")

  local env_cmd = "GOPATH=" .. gopath .. " GOBIN=" .. gobin .. " " .. full_cmd
  local handle = io.popen(env_cmd .. " 2>>" .. opts.log_file .. " 1>>" .. opts.log_file)

  if not handle then
    return {
      error = "Failed to run command: " .. full_cmd
    }
  end

  local output = handle:read("*a")
  handle:close()

  -- Get version information
  local get_version = function()
    local repo_handle = io.popen("echo '" .. input .. "' | cut -d/ -f2- | cut -d@ -f1")
    if not repo_handle then
      return "x.x.x"
    end
    local repo = repo_handle:read("*l")
    repo_handle:close()

    if not repo or repo == "" then
      return "x.x.x"
    end

    local curl_handle = io.popen('curl -s "https://api.github.com/repos/' .. repo .. '/releases/latest"')
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
    ---@diagnostic disable-next-line: redefined-local
    local repo_handle = io.popen("echo '" .. input .. "' | cut -d@ -f1")
    if not repo_handle then
      return "x.x.x"
    end
    local repo_with_host = repo_handle:read("*l")
    repo_handle:close()

    if not repo or repo == "" then
      return "x.x.x"
    end
    local git_handle = io.popen('git ls-remote --tags "https://' .. repo_with_host .. '.git" 2>/dev/null')
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

  -- Find the executable - SIMPLIFIED and more reliable
  local find_executable = function()
    -- First, try a simple ls approach
    local ls_handle = io.popen("ls " .. gobin .. "/* 2>/dev/null | head -1")
    if ls_handle then
      local executable_path = ls_handle:read("*l")
      ls_handle:close()
      if executable_path then
        return executable_path
      end
    end

    -- Fallback to find if ls doesn't work
    local find_handle = io.popen("find " .. gobin .. " -type f -name '*' 2>/dev/null | head -1")
    if find_handle then
      local executable_path = find_handle:read("*l")
      find_handle:close()
      if executable_path then
        return executable_path
      end
    end

    -- Debug: see what's actually in the directory
    local debug_handle = io.popen("ls -la " .. gobin .. " 2>&1")
    if debug_handle then
      local debug_output = debug_handle:read("*a")
      debug_handle:close()
    end

    return {
      error = "Failed to find executable in " .. gobin
    }
  end

  local executable_path = find_executable()
  if type(executable_path) == "table" and executable_path.error then
    return executable_path
  end

  local version = get_version()


  -- Verify the executable actually exists
  local check_exists = io.popen("test -f '" .. executable_path .. "' && echo exists")
  local exists = check_exists and check_exists:read("*l")
  if check_exists then check_exists:close() end

  if exists ~= "exists" then
    return {
      error = "No executable found after installation. Check go logs for errors."
    }
  end

  return {
    version = version,
    path = executable_path
  }
end

-- get the first argument
local input = arg[1]

local pkg = install(input, {
  log_file = "/var/log/pkg/go.log"
})

if pkg.error then
  print(pkg.error)
  os.exit(1)
end

print(pkg.path .. ',' .. pkg.version)
