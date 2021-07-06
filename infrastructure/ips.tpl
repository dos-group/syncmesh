%{ for instance in instances ~}
${instance.network_interface.0.access_config.0.nat_ip},${instance.network_interface.0.network_ip}
%{ endfor ~}