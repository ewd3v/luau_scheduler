return {
	lute = {
		lint = {
			rulepaths = { "luau_packages/lute_std_lint.luau" },
			ruleconfigs = {
				["std"] = {
					-- https://github.com/ewd3v/lute_std_lint#options
					options = {
						allow = {},
					},
				},
			},
		},
	},
}
