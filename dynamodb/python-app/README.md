# Example of connecting to DynamoDB from a Python app

## Pre-req

```shell
python -m venv venv
source venv/bin/activate
pip install boto3
```

or just (in new shell if package already installed):

```shell
source venv/bin/activate
```

> ***AWS credentials***
>
> This app will (re)use the `aws configure` settings as described in the [docs](https://boto3.amazonaws.com/v1/documentation/api/latest/guide/quickstart.html#configuration)

## Run

```shell
python -u main.py
```
