# Resellio

Resellio is a ticketing platform designed to simplify and automate the process of buying and selling tickets for various events such as concerts, sports matches, theater performances, and conferences. The platform caters to three primary roles:

- **User:** Can browse events, purchase tickets, manage their ticket portfolio, and even resell tickets in a secure and regulated manner.
- **Organizer:** Responsible for creating and managing events. Organizers can edit event details, manage ticket allocations, and communicate with users.
- **Administrator:** Oversees the entire system by verifying organizer accounts, managing users, and ensuring the platform operates smoothly and securely.

## Technologies

- **Frontend:** Developed using Flutter for a responsive and engaging user interface.
- **Backend:** Powered by FastAPI (Python) to provide robust and scalable API services.
- **Deployment:** Utilizes Terraform and Docker to manage cloud infrastructure and containerization.

This repository marks the initial setup of the project, with more features and refinements to be added in future iterations.


# Development

### Code Style

This repository uses pre-commit hooks with forced Python formatting ([black](https://github.com/psf/black), [flake8](https://flake8.pycqa.org/en/latest/), and [isort](https://pycqa.github.io/isort/)):

```sh
pip install pre-commit
pre-commit install
```

Whenever you execute `git commit`, the files that were altered or added will be checked and corrected. Tools such as `black` and `isort` may modify files locally—in which case you must `git add` them again. You might also be prompted to make some manual fixes.

To run the hooks against all files without running a commit:

```sh
pre-commit run --all-files
```