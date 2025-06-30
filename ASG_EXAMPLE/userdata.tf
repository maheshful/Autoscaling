data "template_file" "init" {
  template = file("${path.module}/example.tpl")
  vars = {
    hostname = format("demo-%s", local.hostname)
  }
}