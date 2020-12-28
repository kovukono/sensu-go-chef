module SensuCookbook
  module Helpers
    module SensuCtl
      def sensuctl_bin
        if node['platform'] != 'windows'
          '/usr/bin/sensuctl'
        else
          'c:\Program Files\Sensu\sensu-cli\bin'
        end
      end

      def sensuctl_configure_opts
        opts = []
        opts << '--non-interactive'
        opts << ['--username', new_resource.username] unless new_resource.username.nil?
        opts << ['--password', new_resource.password] unless new_resource.password.nil?
        opts << ['--url', new_resource.backend_url] unless new_resource.backend_url.nil?
        opts
      end

      def sensuctl_configure_cmd
        if node['platform'] != 'windows'
          [sensuctl_bin, 'configure', sensuctl_configure_opts].flatten
        else
          ['sensuctl.exe', 'configure', sensuctl_configure_opts].flatten.join(' ')
        end
      end

      def sensuctl_asset_update_opts
        opts = []
        opts << ['--namespace', new_resource.namespace] if new_resource.namespace
      end

      def sensuctl_asset_update_cmd
        [sensuctl_bin, 'asset', 'update', new_resource.name, sensuctl_asset_update_opts].flatten
      end

      require 'win32/registry'

      def get_reg_env(hkey, subkey, &block)
        Win32::Registry.open(hkey, subkey) do |reg|
          reg.each_value do |name|
            value = reg.read_s_expand(name)
            if block && ENV.key?(name)
              ENV[name] = block.call(name, ENV[name], value)
            else
              ENV[name] = value
            end
          end
        end
      end

      def refresh_env
        get_reg_env(Win32::Registry::HKEY_LOCAL_MACHINE, 'System\CurrentControlSet\Control\Session Manager\Environment')
        get_reg_env(Win32::Registry::HKEY_CURRENT_USER, 'Environment') do |name, old_value, new_value|
          if name.upcase == 'PATH'
            old_value || File::PATH_SEPARATOR || new_value
          else
            new_value
          end
        end
      end
    end
  end
end
