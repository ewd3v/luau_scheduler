# luau_package_template
A project template for [Luau](https://luau.org/) packages

## Quickstart

First clone this template, either by using the ["Use this template" button on GitHub](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template), or by cloning it manually ([zip](https://github.com/ewd3v/luau_package_template/archive/refs/heads/main.zip)).

Open the repository in your favorite IDE, [VSCode](https://code.visualstudio.com/) is recommended (or anything based on it like [VSCodium](https://vscodium.com/)) as this template already contains [workspace settings](/.vscode/settings.json) and [recommended extensions](/.vscode/extensions.json) for a good workflow.

[Install and setup mise](https://mise.jdx.dev/getting-started.html). Mise is the tool this template uses to manage tooling required for running workflow tasks.

Next we need to clean out and replace any unneccary files from the template. There's a mise task that can do most of this for you and automatically initialize new files, which you can run with:
```bash
mise run scaffold
```

## Changesets

This template ships with [Changesets](https://changesets.dev/), which is a tool to manage package versioning and changelogs. It's made for [npm](https://www.npmjs.com/) packages, which is why this template keeps a `package.json` file, which will automatically sync with `pesde.toml` when changeset makes any modifications to it.

When you make any changes that you'd like to document in your changelog (or need to bump package version), simply just run `changeset` and it'll create a changeset file in /.changeset for you. When you commit and push this file to the repository the [release workflow](/.github/workflows/release.yml) will automatically create a pull request to bump the package version for you. You will need to allow actions to create pr's in the GitHub repository settings, otherwise you'll need to create the pr manually (check workflow logs). <br>
When you merge this pr, the action workflow should also create a new GitHub release for you. After which you can [publish your package with pesde](https://docs.pesde.dev/guides/publishing/).

## @std linting

This template also ships with [lute_std_lint](https://github.com/ewd3v/lute_std_lint#lute_std_lint) configured. It's purpose is to help you document what [standard libraries](https://lute.luau.org/std/) your package is using to help others know if it will run on their Luau runtime. You can find the config for it in [`src.config.luau`](/src.config.luau). However to make this more accessible to others you can also document your @std usage in your README.md like [shown here](https://github.com/ewd3v/lute_std_lint#required-libraries).

## Monorepo

A monorepo setup is nice when you work on multiple package that relate to eachother. Changesets natively supports this, and pesde has [workspaces](https://docs.pesde.dev/guides/workspaces/) to make working with multiple packages at the same time trivial.

An exampe of a setup like this may be created in the future, however if want to make a setup yourself you'll need to update [`sync_project_version.luau`](/scripts/sync_package_version.luau) to sync all of your `package.json` files so your `pesde.toml` files stay in sync after changeset bumps the package versions.
