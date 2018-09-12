resource "aws_key_pair" "oracleDockerEC2_key_pair" {
  key_name = "oracleDockerEC2_key_pair"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}