%{ for instance in instances ~}
${try(instance.network_interface.0.access_config.0.nat_ip, "none")},${instance.network_interface.0.network_ip}
%{ endfor ~}