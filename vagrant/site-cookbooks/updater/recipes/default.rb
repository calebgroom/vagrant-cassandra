bash "freshen_apt" do
  user "root"
  cwd "/tmp"
  code <<-EOH
  apt-mark hold linux-headers-server linux-image-server linux-server linux-libc-dev linux-firmware
  apt-get update
  EOH
end
