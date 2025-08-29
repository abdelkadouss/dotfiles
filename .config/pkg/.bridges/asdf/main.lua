---@diagnostic disable: redefined-local
local install = function(input, opts)
  local to_log_file = " 2>>" .. opts.log_file .. " 1>>" .. opts.log_file

  local working_dir = io.popen("pwd"):read("*a")
  local env_prefix = "ASDF_DATA_DIR" .. "=" .. working_dir

  -- install the plugin
  local plugin_name = opts.plugin or input

  local cmd = { env_prefix, "asdf", "plugin", "add", plugin_name }
  local install_plugin = os.execute(table.concat(cmd, " ") .. to_log_file)

  if not install_plugin then
    return {
      error = "Failed to install plugin"
    }
  end

  -- install the version
  local version = opts.version or "latest"
  local cmd = { env_prefix, "asdf", "install", input, version }

  local install_version = os.execute(table.concat(cmd, " ") .. to_log_file)

  if not install_version then
    return {
      error = "Failed to install version"
    }
  end

  local list_versions = io.popen(env_prefix .. " asdf list ")

  if not list_versions then
    return {
      error = "Failed to list versions"
    }
  end

  local output = list_versions:lines()

  local output_lines = {}
  for line in list_versions:lines() do
    table.insert(output_lines, line)
  end

  if #output_lines ~= 2 then
    return {
      error = "Failed to list versions,'asdf list' output: " .. table.concat(output_lines, "\n")
    }
  end

  local version = output_lines[2]:match("^%s*(.-)%s*$")

  local version = version or "x.x.x"

  -- get the path
  os.execute("mkdir -p out")
  local get_installed_stuff = { "mv", "./installs/", input, "/*/*", "./out" }

  local handle = io.popen(table.concat(get_installed_stuff, " ") .. to_log_file)

  if not handle then
    return {
      error = "Failed to get installed stuff"
    }
  end

  handle:close()

  local path = working_dir .. "/out"
  local entry_point = opts.entry_point or ("bin/" .. input)
  local entry_point = path .. "/" .. entry_point

  return {
    version,
    path,
    entry_point
  }
end

return { install = install }
