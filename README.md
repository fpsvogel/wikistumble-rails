<h1 align="center">Wiki Stumble</h1>

Welcome to the Wiki Stumble codebase. This app started out as an exercise which [you can read all about on my blog](https://fpsvogel.com/posts/2021/wikipedia-explorer-discover-articles-like-stumbleupon). I'll be expanding it as I read Jason Swett's [Complete Guide to Rails Testing](https://www.codewithjason.com/complete-guide-to-rails-testing/), applying its lessons to the app.

### Table of Contents

- [Why this is on my GitHub portfolio](#why-this-is-on-my-github-portfolio)
- [Contributing](#contributing)
- [Requirements](#requirements)
- [Initial setup](#initial-setup)
- [License](#license)

## Why this is on my GitHub portfolio

In this app I wrote a comprehensive RSpec test suite for the first time. (My previous experience had been mostly with Minitest.) I also [had to get creative](https://app.asana.com/0/1173460490611336/1201525792008781/f) to work around the limitations of the Wikipedia APIs.

The result is an app that surely can (and will) be improved and expanded, but is nevertheless an original solution to a previously unsolved problem: how to explore Wikipedia without the hit-or-miss results of totally random pages, and without slogging through long topic lists. In Wiki Stumble, the user gets personalized recommendations of articles based on user-selected categories and also based on the user’s reaction (thumbs up or down) to previous recommendations.

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
- If this is your first time using PostgreSQL, log in to PostgreSQL and create a user:
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
