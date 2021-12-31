output "first_node_id" {
    value = aws_spot_instance_request.first.spot_instance_id
}

output "second_node_id" {
    value = aws_spot_instance_request.second.spot_instance_id
}