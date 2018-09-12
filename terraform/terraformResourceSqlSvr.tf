resource "aws_instance" "ec2_oracleDockerEC2_oracle" {
  count = 1
  ami = "ami-759bc50a"
  instance_type = "t2.small"
  key_name = "${aws_key_pair.oracleDockerEC2_key_pair.key_name}"
  security_groups = ["${aws_security_group.oracleDockerEC2_oracle.name}"]
  provisioner "remote-exec" {
    connection {
      type = "ssh",
      user = "ubuntu",
      private_key = "${file("~/.ssh/id_rsa")}"
    }
    script = "terraformProvisionOracleUsingDocker.sh"
  }
  tags {
    Name = "oracleDockerEC2 Oracle ${format("%03d", count.index)}"
  }
}