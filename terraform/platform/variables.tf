locals {
  configs = {
    defaults = {
      # TODO

    }

    test = {
      # Short environment name
      env = "test"
      #
      project = "nof-emanuel"
      #
      location            = "West Europe"
      resource_group_name = "Vasyl-Candidate"
    }
  }

  config = merge(local.configs["defaults"], local.configs[terraform.workspace])
  env    = local.config["env"]
}
