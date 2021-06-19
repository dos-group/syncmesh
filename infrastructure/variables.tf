variable "instance_count" {
  type    = number
  default = 3
}

variable "ssh_keys" {
  type = list(object({
    keymaterial = string
    user = string
  }))
  description = "list of public ssh keys that have access to the VMs"
  default = [
      {
        user = "dnhb"
        keymaterial = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDSbM+h0IAyf0uY6NQgyHj80IDwyPsmRpuoOXT6mkEqG05xCBk28iXsqgofP+4RXQFjHSFmQf+9Jb+TtQfg938fq6Nok+G3/iTQJAP+YlC+1nomup5iBRBb7BDJqtDJJPxgFo6J8xx+Ivcuy9xEwenbsEX6NNCNCtCsG8301R26MdYePz0BjPO+krfojI1pVyLH2rN6NcDiUM9FwZV2SYFRiVxEvdbGt6kqcLZAISN0Gq761MU0nVMCbQYkmq78Rzo2hZMYShHmhsLqIlH3A0zyznp8huYBe6PX/Tg1Vwm6193YTPmqnNmC+ibMD87PbdzizLKz3lncUKDTF2H0+7xVr2SanDzfYNfKIEPVO8ud1QXvWzxcdXWyzCjhomEbKPMjQIg6Dlz59lukX/geb2XYDOs9XEYsri/rhfXyrUJY0w5fgse1/PEH+1V3mgr1KN5zpinudijEyGE02dcKS8me5RIx9TUPlk5BXRgDAWVmkbtJSncODfo5ha10DvZJtKk= dnhb"
      }
  ]
}
