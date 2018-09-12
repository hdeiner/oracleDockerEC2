output "oracle_dns" {
  value = ["${aws_instance.ec2_oracleDockerEC2_oracle.*.public_dns}"]
}

output "sqlsvr_ip" {
  value = ["${aws_instance.ec2_oracleDockerEC2_oracle.*.public_ip}"]
}