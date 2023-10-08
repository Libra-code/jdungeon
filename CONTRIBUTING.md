# How to contribute
Follow the next steps to contribute your changes towards to project.

## Contribution steps

### Fork the Repository

On the project's GitHub page, click the "Fork" button in the upper right corner. This creates a copy of the project's repository in your GitHub account.

### Clone the Forked Repository

Clone the forked repository to your local machine using the git clone command. Replace <your-forked-repo-url> with the actual URL of your forked repository:

```bash
git clone <your-forked-repo-url>
```

### Set Up Upstream Remote

Add a remote reference to the original project repository. This allows you to keep your forked repository in sync with any changes in the original repository:

```bash
git remote add upstream <original-repo-url>
```

### Create a New Branch

Before making any changes, create a new branch for your contribution. This helps keep your changes isolated from the main branch:

```bash
git checkout -b <branch-name>
```

### Make Changes

Make the desired changes or additions to the codebase in your local branch.

### Test your changes

Test if your changes work. Make also sure that your changes don't break other functionality of the game.

### Use Code Style for Scripts

JDungeon uses the code style defined by [GDtoolkit](https://pypi.org/project/gdtoolkit/). Use this tool to format your code. It can also be added as a plugin to VSCode.

### Commit Changes

After making changes, commit them with a meaningful commit message:

```bash
git add .
git commit -m "Your descriptive commit message here"
```

### Sync with Upstream

Before pushing your changes, sync your forked repository with the original repository to ensure you're working with the latest code:

```bash
git fetch upstream
git merge upstream/main  # or the appropriate branch
```

### Resolve Conflicts (If Any)

If there are conflicts between your changes and the upstream changes, resolve them in your local repository.

### Push Changes: Push your changes to your forked repository on GitHub

```bash
git push origin <branch-name>
```

### Create a Pull Request (PR)

On your forked repository's GitHub page, you'll see a prompt to create a pull request from your branch to the original repository's main branch. Fill in the necessary details, including a descriptive title and a clear description of your changes.

If your changes consists of UI or art stuff make sure to add some screenshots to showcase them.

### Engage in Discussions/Comments

Your PR might undergo review, feedback, and discussions. Be responsive and willing to make necessary changes based on feedback.

### Finalize and Merge

Once your changes are approved and any requested changes are made, the project maintainers will merge your PR into the main repository.

### Celebrate Your Contribution!

Congratulations, you've successfully contributed to an open-source project! Your changes are now part of the project's codebase.