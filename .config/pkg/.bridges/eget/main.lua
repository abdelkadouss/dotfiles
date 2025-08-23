local install = function(input, opts)
  local to_log_file = " 2>>" .. opts.log_file .. " 1>>" .. opts.log_file
  print(opts.log_file)

  -- Create output directory
  os.execute("mkdir -p out")

  -- Build the command
  local cmd = { "eget", "--to", "out" }

  if opts.file and opts.file ~= "" then
    table.insert(cmd, "--file")
    table.insert(cmd, opts.file)
  elseif opts.all == true then
    table.insert(cmd, "--all")
  elseif opts.keep_structure == true then
    table.insert(cmd, "--download-only")
  end

  if opts.asset and opts.asset ~= "" then
    table.insert(cmd, "--asset")
    table.insert(cmd, opts.asset)
  end

  if opts.tag and opts.tag ~= "" then
    table.insert(cmd, "--tag")
    table.insert(cmd, opts.tag)
  end

  table.insert(cmd, input)

  -- Run the command
  local handle = io.popen(table.concat(cmd, " ") .. to_log_file)

  if not handle then
    return {
      error = "Failed to run eget command"
    }
  end

  local result = handle:read("*a")
  handle:close()

  print(result)

  -- helper functions
  local function execute(cmd)
    return os.execute(cmd .. " > /dev/null 2>&1")
  end

  -- Function to capture shell command output
  local function capture(cmd)
    local handle = io.popen(cmd .. " 2>&1")
    if not handle then
      return {
        error = "Failed to run command: " .. cmd
      }
    end
    local result = handle:read("*a")
    handle:close()
    return result:gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
  end

  -- Function to check if path exists and is a directory
  local function is_dir(path)
    return execute("test -d '" .. path .. "'")
  end

  -- Function to list files in directory
  local function list_files(dir)
    local files = {}
    local handle = io.popen("ls -1A '" .. dir .. "' 2>/dev/null")
    if handle then
      for file in handle:lines() do
        table.insert(files, file)
      end
      handle:close()
    end
    return files
  end

  -- get the out absolute path
  local pwd_handle = io.popen("pwd")

  if not pwd_handle then
    return {
      error = "Failed to get current directory"
    }
  end

  local current_dir = pwd_handle:read("*l")

  local path = current_dir .. "/"
  local entry_point = nil

  pwd_handle:close()
  if opts.keep_structure == true then
    if not execute("mkdir -p res") then
      return {
        error = "Failed to create output directory"
      }
    end

    local tar_files = capture("find ./out -name '*.tar*' -type f 2>>/dev/null | head -1")
    if tar_files == "" then
      return {
        error = "No tar files found in ./out"
      }
    end

    print("Extracting: " .. tar_files)
    if not execute("tar -xf ./out/*.tar* -C res") then
      return {
        error = "Failed to extract tar file"
      }
    end

    local files = list_files("res")

    if #files == 1 then
      local only_item = files[1]
      local item_path = "res/" .. only_item

      if is_dir(item_path) then
        print("Found single directory: " .. only_item)
        print("Moving contents to root...")

        -- Create temporary directory
        if not execute("mkdir -p tmp") then
          return {
            error = "Failed to create temporary directory"
          }
        end

        -- Move everything from out to tmp
        if not execute("mv res/* tmp/") then
          return {
            error = "Failed to move contents to temporary directory"
          }
        end
        if not execute("rm -rf out && mkdir -p out") then
          return {
            error = "Failed to remove out directory"
          }
        end

        -- Move contents from subdirectory back to out
        if not execute("mv tmp/" .. only_item .. "/* out/") then
          return {
            error = "Failed to move contents back to out directory"
          }
        end

        -- Cleanup
        execute("rm -rf tmp && rm -rf res")
        -- execute("rmdir out/" .. only_item .. " 2>/dev/null")

        print("Contents moved successfully!")
      else
        print("Single file found, keeping as is")
      end
    else
      print("Multiple items found, keeping original structure")
    end


    path = path .. "out"

    entry_point = path .. "/" .. opts.entry_point
    if not entry_point then
      return {
        error = "the entry_point field is required when keep_structure is true"
      }
    end

  elseif opts.target then
    path = path .. "out/" .. opts.target
  else
    -- Try to find the first file in out directory
    local dir = io.popen("ls out")

    if not dir then
      return {
        error = "Failed to list files in out directory"
      }
    end

    local files = {}
    for file in dir:lines() do
      table.insert(files, file)
    end
    dir:close()


    path = current_dir .. "/out/"
    if #files > 0 then
      path = path .. files[1]
    else
      return {
        error = "No files found in out directory after perform the install script!"
      }
    end
  end

  -- Pure Lua version detection without HTTP dependencies
  local get_version = function()
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

  if not entry_point then
    return {
      version = get_version() or "x.x.x",
      path = path
    }
  else
    return {
      version = get_version() or "x.x.x",
      path = path,
      entry_point = entry_point
    }
  end
end

return { install = install }
