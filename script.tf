resource "aws_lambda_function" "addjob"{

    filename = "./addjob.zip"

    function_name = "addjob"

    role = "arn:aws:iam::604000966203:role/service-role/AddJob-role-uzvfjj3k"

    handler = "addjob.handler"

    runtime = "nodejs14.x"

    source_code_hash = "./addjob.zip"

    environment  {

        variables = {

            TABLE_NAME = "JOB"

        }

    }

}



