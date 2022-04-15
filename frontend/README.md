- [Setup Instructions](#setup-instructions)
- [Environment Variables](#environment-variables)
- [Deploying the application](#deploying-the-application)
- [TODO](#todo)


## Setup Instructions

To deploy everything including the infrastructure, please refer to either [Cloudformation](../cloudformation) or [Terraform](../terraform).

1. Install the [latest stable](https://nodejs.org/en/) version of NodeJS.

2. Clone the repository
3. Setup a `.env` file with the environment variables populated refer to [Environment Variables section](#environment-variables).
4. navigate to frontend directory and run the following:
```bash
npm install
```
5. Start the development server, run the following:

```bash
npm start
```

Then navigate to [localhost:3000](localhost:3000) in your browser.

## Environment Variables

Environments variables are stored in `.env` file, which has the following variables:

```
API_ENDPOINT=https://example.execute-api.example-region.amazonaws.com/prod/
PORT=3000
LOCAL_ORIGIN=http://localhost:3000
```

For the React portion of the application, these variables are baked in at compile time using webpack's [Define plugin](https://webpack.js.org/plugins/define-plugin/). See webpack.config.js for the defined variables and how to reference them in code.

For variables defined for the Node.JS portion of the application, these can be referenced directly in code using

```
process.env.SOME_ENVIRONMENT_VARIABLE
```

## Deploying the application

The repository doesn't contain build files. It is expected that when the site is deployed, it will be built on the server. This means that environment variables need to be configured on the server as well.

Building and running the application in production mode can be triggered by running:

```bash
npm run start-server
```

## TODO
- [ ] Cognito
