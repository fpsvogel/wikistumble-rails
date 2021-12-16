<h1 align="center">Wiki Stumble</h1>

Welcome to the [Wiki Stumble](https://wikistumble.herokuapp.com/) codebase. This app started out as an experiment which [you can read all about on my blog](https://fpsvogel.com/posts/2021/wikipedia-explorer-discover-articles-like-stumbleupon). I'll be expanding it as I read Jason Swett's [Complete Guide to Rails Testing](https://www.codewithjason.com/complete-guide-to-rails-testing/), applying its lessons to the app.

### Table of Contents

- [Contributing](#contributing)
- [Requirements](#requirements)
- [Initial setup](#initial-setup)
- [License](#license)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fpsvogel/wikistumble.

## Requirements

- Ruby 3+
- Node.js 14+
- PostgreSQL 9.3+

## Initial setup

- Checkout the wikistumble git tree from Github:
    ```sh
    $ git clone git://github.com/fpsvogel/wikistumble.git
    $ cd wikistumble
    wikistumble$
    ```
- Run Bundler to install gems needed by the project:
    ```sh
    wikistumble$ bundle
    ```
- Log in to PostgreSQL and create a user:
    ```
    $ psql -U postgres
    postgres=# create role "your_username" login createdb
    postgres=# exit
    ```
- Create the development and test databases:
    ```sh
    wikistumble$ rails db:create
    ```
  - If you see an error about peer authentication, then you need to [change one or two settings in pg_hba.conf](https://stackoverflow.com/questions/18664074/getting-error-peer-authentication-failed-for-user-postgres-when-trying-to-ge), then try creating the databases again.
- Load the schema into the new database:
    ```sh
    wikistumble$ rails db:schema:load
    ```
- Seed the database:
    ```sh
    wikistumble$ rails db:seed
    ```

## License

Distributed under the [MIT License](https://opensource.org/licenses/MIT).
