resource "aws_api_gateway_rest_api" "reaperui" {
  count       = "${var.ui == true ? 1 : 0}"
  name        = "WSR-${lower(var.TFE_ORG)}"
  description = "Terraform Workspace Reaper"
}

resource "aws_api_gateway_resource" "proxy" {
  count       = "${var.ui == true ? 1 : 0}"
  rest_api_id = "${aws_api_gateway_rest_api.reaperui.id}"
  parent_id   = "${aws_api_gateway_rest_api.reaperui.root_resource_id}"
  path_part   = "reaper"
}

resource "aws_api_gateway_method" "proxy" {
  count         = "${var.ui == true ? 1 : 0}"
  rest_api_id   = "${aws_api_gateway_rest_api.reaperui.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  count       = "${var.ui == true ? 1 : 0}"
  rest_api_id = "${aws_api_gateway_rest_api.reaperui.id}"
  resource_id = "${aws_api_gateway_method.proxy.resource_id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.reaper_ui.invoke_arn}"
}

resource "aws_api_gateway_deployment" "example" {
  count = "${var.ui == true ? 1 : 0}"

  depends_on = [
    "aws_api_gateway_integration.lambda",
    "aws_api_gateway_resource.proxy",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.reaperui.id}"
  stage_name  = "Production"
}

resource "aws_lambda_permission" "apigw" {
  count         = "${var.ui == true ? 1 : 0}"
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.reaper_ui.arn}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_deployment.example.execution_arn}/*/*"
}
