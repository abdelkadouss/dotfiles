local install = function(input, opts)
  -- Create output directory and clean it
  os.execute("mkdir -p out && rm -rf out/* 2>/dev/null")

  local cmd
  if opts.crate then
    cmd = { "cargo", "install", input, "--root", "out" }
    if opts.features then
      table.insert(cmd, "--features")
      table.insert(cmd, opts.features)
    end
  elseif opts.git then
    cmd = { "cargo", "install", "--git", input, "--root", "out" }
    if opts.branch then
      table.insert(cmd, "--branch")
      table.insert(cmd, opts.branch)
    elseif opts.tag then
      table.insert(cmd, "--tag")
      table.insert(cmd, opts.tag)
    elseif opts.rev then
      table.insert(cmd, "--rev")
      table.insert(cmd, opts.rev)
    end
    if opts.features then
      table.insert(cmd, "--features")
      table.insert(cmd, opts.features)
    end
  else
    cmd = { "cargo", "binstall", input, "--root", "out", "-y" }
    if opts.version then
      table.insert(cmd, "--version")
      table.insert(cmd, opts.version)
    end
  end

  -- Run the installation command
  local full_cmd = table.concat(cmd, " ")
  print("Running:", full_cmd)
  local handle = io.popen(full_cmd .. " 2>>" .. opts.log_file .. " 1>>" .. opts.log_file)
  if not handle then
    return {
      error = "Failed to run command: " .. full_cmd
    }
  end
  print("trying to read the output")
  local output = handle:read("*a")
  handle:close()
  print("output: " .. output)

  -- Get version using cargo info
  local get_version = function()
    print("Getting version")
    local version = "x.x.x"

    local info_handle = io.popen("cargo info " .. input .. " 2>/dev/null")
    if info_handle then
      local info_output = info_handle:read("*a")
      info_handle:close()

      for line in info_output:gmatch("[^\r\n]+") do
        if line:match("^version: ") then
          version = line:match("^version:%s+(%S+)")
          break
        end
      end
    end

    if version == "x.x.x" then
      local curl_handle = io.popen('curl -s ' .. input .. '/releases/latest"')
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
            version = tag
          end
        end
      end

      -- Method 2: Use git tags if available (for development versions)
      local git_handle = io.popen('git ls-remote --tags "' .. input .. '"  2>/dev/null')
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
          version = latest_tag
        end
      end
    end

    print("Version:", version)
    return version
  end

  -- Find the actual executable (Cargo packages are always single executables)
  local find_executable = function()
    local pwd_handle = io.popen("pwd")
    if not pwd_handle then
      return {
        error = "Failed to get current directory"
      }
    end
    local current_dir = pwd_handle:read("*l")
    pwd_handle:close()

    -- Look for the executable and return absolute path
    local find_handle = io.popen("find out -type f ! -name '*.*' 2>/dev/null | head -1")
    if find_handle then
      local relative_path = find_handle:read("*l")
      find_handle:close()
      if relative_path then
        return current_dir .. "/" .. relative_path
      end
    end
    return {
      error = "Failed to find executable"
    }
  end

  local executable_path = find_executable()
  if not executable_path then
    return {
      error = "Failed to find executable"
    }
  end
  local version = get_version()
  if not version then
    return {
      error = "Failed to get version"
    }
  end

  print("Executable path:", executable_path)
  print("Version:", version)

  -- Verify the executable actually exists
  local check_exists = io.popen("test -f " .. executable_path .. " && echo exists")
  local exists = check_exists and check_exists:read("*l")
  if check_exists then check_exists:close() end

  if exists ~= "exists" then
    return {
      error = "No executable found after installation. Check cargo logs for errors."
    }
  end

  -- Cargo packages are always single executables
  return {
    version = version,
    path = executable_path
  }
end

return { install = install }
