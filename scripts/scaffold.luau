local fs = require("@std/fs")
local io = require("@std/io")
local process = require("@std/process")
local stringext = require("@std/stringext")

if
	string.lower(
		stringext.trim(
			io.input(
				"Are you sure you want to scaffold a new project? This will remove some files from the upstream template.\n(y/N) "
			)
		)
	) ~= "y"
then
	print("cancelled")
	return
end

do -- changeset
	local configPath = ".changeset/config.json"
	local configContents: string?
	if fs.exists(configPath) then
		configContents = fs.readFileToString(configPath)
	else
		print("failed to get template changeset config, using default config instead (consider resolving this)")
	end

	pcall(fs.removeDirectory, ".changeset", { recursive = true })
	process.run({ "changeset", "init" }, { stdio = "inherit" })

	if configContents ~= nil then
		fs.writeStringToFile(configPath, configContents)
	end
end

do -- LICENSE
	pcall(fs.remove, "LICENSE")
	print("removed LICENSE, remember to create a new one!")
end

pcall(fs.remove, "pesde.lock")
pcall(fs.remove, "pesde.toml")

process.run({ "pesde", "init" }, { stdio = "inherit" })
local pesdeContents = fs.readFileToString("pesde.toml")

local fullPackageName = assert(string.match(pesdeContents, 'name = "(.-)"'), "failed to find package name")
local packageNameParts = string.split(fullPackageName, "/")
local packageName = assert(packageNameParts[2], "failed to get package name")

local packageDescription = string.match(pesdeContents, 'description = "(.-)"') or ""

fs.writeStringToFile("README.md", `# {packageName}\n{packageDescription}\n`)
fs.writeStringToFile(
	"package.json",
	`\{\n    "name": "{fullPackageName}",\n    "version": "0.0.0",\n    "private": true\n}`
)
