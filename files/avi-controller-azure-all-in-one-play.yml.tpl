---
- hosts: localhost
  connection: local
  gather_facts: no
  roles:
    - role: avinetworks.avisdk
  vars:
    avi_credentials:
        controller: "localhost"
        username: "admin"
        password: "{{ password }}"
        api_version: ${avi_version}
    username: admin
    password: "{{ password }}"
    api_version: ${avi_version}
    cloud_name: "Default-Cloud"
    controller_ip:
      ${ indent(6, yamlencode(controller_ip))}
    controller_names:
      ${ indent(6, yamlencode(controller_names))}
    ansible_become: yes
    ansible_become_password: "{{ password }}"
    subscription_id: ${subscription_id}
    se_resource_group: ${se_resource_group}
    se_vnet_id_path: ${se_vnet_id_path}
    se_mgmt_subnet_name: ${se_mgmt_subnet_name}
    region: ${region}
    use_standard_alb: ${use_standard_alb}
    se_vm_size: ${se_vm_size}
    se_ha_mode: ${se_ha_mode}
    se_name_prefix: ${se_name_prefix}
    controller_ha: ${controller_ha}
    use_azure_dns: ${use_azure_dns}
%{ if dns_servers != null ~}
    dns_servers:
%{ for item in dns_servers ~}
      - addr: "${item}"
        type: "V4"
%{ endfor ~}
    dns_search_domain: ${dns_search_domain}
%{ endif ~}
    ntp_servers:
%{ for item in ntp_servers ~}
      - server:
          addr: "${item.addr}"
          type: "${item.type}"
%{ endfor ~}
%{ if configure_dns_profile ~}
    dns_service_domain: ${dns_service_domain}
%{ endif ~}
%{ if configure_dns_vs ~}
    dns_vs_settings: 
      ${ indent(6, yamlencode(dns_vs_settings))}
%{ endif ~}
%{ if configure_gslb && gslb_site_name != "" ~}
    gslb_site_name: ${gslb_site_name}
    additional_gslb_sites:
      ${ indent(6, yamlencode(additional_gslb_sites))}
%{ endif ~}
  tasks:
    - name: Wait for Controller to become ready
      wait_for:
        port: 443
        timeout: 600
        sleep: 5
    - name: Configure System Configurations
      avi_systemconfiguration:
        avi_credentials: "{{ avi_credentials }}"
        state: present
        email_configuration:
          smtp_type: "SMTP_LOCAL_HOST"
          from_email: admin@avicontroller.net
        global_tenant_config:
          se_in_provider_context: true
          tenant_access_to_provider_se: true
          tenant_vrf: false
%{ if dns_servers != null ~}
        dns_configuration:
          server_list: "{{ dns_servers }}"
          search_domain: "{{ dns_search_domain }}"
%{ endif ~}
        ntp_configuration:
          ntp_servers: "{{ ntp_servers }}" 
        portal_configuration:
          allow_basic_authentication: false
          disable_remote_cli_shell: false
          enable_clickjacking_protection: true
          enable_http: true
          enable_https: true
          password_strength_check: false
          redirect_to_https: true
          use_uuid_from_input: false
        welcome_workflow_complete: true
    - name: Create a Cloud connector user that is used for authentication to Azure
      avi_cloudconnectoruser:
        avi_credentials: "{{ avi_credentials }}"
        state: present
        name: azure
        azure_serviceprincipal:
          application_id: "{{ azure_app_id }}"
          authentication_token: "{{ azure_auth_token }}"
          tenant_id: "{{ azure_tenant_id }}"
%{ if configure_cloud ~}
    - name: Configure Cloud
      avi_cloud:
        avi_credentials: "{{ avi_credentials }}"
        state: present
        name: "{{ cloud_name }}"
        vtype: CLOUD_AZURE
        dhcp_enabled: true
        license_type: "LIC_CORES"
        azure_configuration:
          subscription_id: "{{ subscription_id }}"
          location: "{{ region }}"
          cloud_credentials_ref: "/api/cloudconnectoruser?name=azure"
          network_info:
            - virtual_network_id: "{{ se_vnet_id_path }}" 
              se_network_id: "{{ se_mgmt_subnet_name }}"
          resource_group: "{{ se_resource_group }}"
          use_azure_dns: "{{ use_azure_dns }}"
          use_enhanced_ha: false
          use_managed_disks: true
          use_standard_alb: "{{ use_standard_alb }}"
          dhcp_enabled: true
      register: avi_cloud
    - name: Set Backup Passphrase
      avi_backupconfiguration:
        avi_credentials: "{{ avi_credentials }}"
        state: present
        name: Backup-Configuration
        backup_passphrase: "{{ password }}"
        upload_to_remote_host: false
%{ if se_ha_mode == "active/active" }
    - name: Configure SE-Group
      avi_api_session:
        avi_credentials: "{{ avi_credentials }}"
        http_method: post
        path: "serviceenginegroup"
        tenant: "admin"
        data:
          name: "Default-Group" 
          cloud_ref: "/api/cloud?name={{ cloud_name }}"
          ha_mode: HA_MODE_SHARED_PAIR
          min_scaleout_per_vs: 2
          algo: PLACEMENT_ALGO_PACKED
          buffer_se: "0"
          max_se: "10"
          se_name_prefix: "{{ se_name_prefix }}"
          accelerated_networking: true
          instance_flavor: "{{ se_vm_size }}"
          realtime_se_metrics:
            duration: "10080"
            enabled: true
%{ endif }
%{ if se_ha_mode == "n+m" }
    - name: Configure SE-Group
      avi_api_session:
        avi_credentials: "{{ avi_credentials }}"
        http_method: post
        path: "serviceenginegroup"
        tenant: "admin"
        data:
          name: "Default-Group" 
          state: present
          cloud_ref: "{{ avi_cloud.obj.url }}"
          ha_mode: HA_MODE_SHARED
          min_scaleout_per_vs: 1
          algo: PLACEMENT_ALGO_PACKED
          buffer_se: "1"
          max_se: "10"
          se_name_prefix: "{{ se_name_prefix }}"
          accelerated_networking: true
          instance_flavor: "{{ se_vm_size }}"
          realtime_se_metrics:
            duration: "10080"
            enabled: true
%{ endif }
%{ if se_ha_mode == "active/standby" }
    - name: Configure SE-Group
      avi_api_session:
        avi_credentials: "{{ avi_credentials }}"
        http_method: post
        path: "serviceenginegroup"
        tenant: "admin"
        data:
          name: "Default-Group" 
          cloud_ref: "{{ avi_cloud.obj.url }}"
          ha_mode: HA_MODE_LEGACY_ACTIVE_STANDBY
          min_scaleout_per_vs: 1
          buffer_se: "0"
          max_se: "2"
          se_name_prefix: "{{ se_name_prefix }}_se"
          accelerated_networking: true
          instance_flavor: "{{ se_vm_size }}"
          realtime_se_metrics:
            duration: "10080"
            enabled: true
%{ endif }
%{ if configure_dns_profile }
    - name: Create Avi DNS Profile
      avi_ipamdnsproviderprofile:
        avi_credentials: "{{ avi_credentials }}"
        state: present
        name: Avi_DNS
        type: IPAMDNS_TYPE_INTERNAL_DNS
        internal_profile:
          dns_service_domain:
          - domain_name: "{{ dns_service_domain }}"
            pass_through: true
          ttl: 30
      register: create_dns
    - name: Update Cloud Configuration with DNS profile 
      avi_api_session:
        avi_credentials: "{{ avi_credentials }}"
        http_method: patch
        path: "cloud/{{ avi_cloud.obj.uuid }}"
        data:
          add:
            dns_provider_ref: "{{ create_dns.obj.url }}"
%{ endif }
%{ if configure_gslb && create_gslb_se_group }
    - name: Configure GSLB SE-Group
      avi_api_session:
        avi_credentials: "{{ avi_credentials }}"
        http_method: post
        path: "serviceenginegroup"
        tenant: "admin"
        data:
          name: "g-dns" 
          cloud_ref: "{{ avi_cloud.obj.url }}"
          ha_mode: HA_MODE_SHARED
          algo: PLACEMENT_ALGO_PACKED
          buffer_se: "1"
          max_se: "4"
          max_vs_per_se: "2"
          extra_shared_config_memory: 2000
          se_name_prefix: "{{ se_name_prefix }}"
          realtime_se_metrics:
            duration: "10080"
            enabled: true
      register: gslb_se_group
%{ endif}
%{ if configure_dns_vs ~}
    - name: DNS VS Config | Get Subnet Information
      avi_api_session:
        avi_credentials: "{{ avi_credentials }}"
        http_method: get
        path: "vimgrnwruntime?name={{ dns_vs_settings.subnet_name }}"
      register: dns_vs_subnet
    - name: Create DNS VSVIP
      avi_api_session:
        avi_credentials: "{{ avi_credentials }}"
        http_method: post
        path: "vsvip"
        tenant: "admin"
        data:
          east_west_placement: false
          cloud_ref: "/api/cloud?name={{ cloud_name }}"
%{ if configure_gslb && create_gslb_se_group ~}
          se_group_ref: "{{ gslb_se_group.obj.url }}"
%{ endif ~}
          vip:
          - enabled: true
            vip_id: 0      
            auto_allocate_ip: "true"
            auto_allocate_floating_ip: "{{ dns_vs_settings.allocate_public_ip }}"
            avi_allocated_vip: true
            avi_allocated_fip: "{{ dns_vs_settings.allocate_public_ip }}"
            auto_allocate_ip_type: V4_ONLY
            prefix_length: 32
            subnet_uuid: "{{ dns_vs_subnet.obj.results.0.url }}"
            placement_networks: []
            ipam_network_subnet:
              network_ref: "{{ dns_vs_subnet.obj.results.0.url }}"
              subnet:
                ip_addr:
                  addr: "{{ dns_vs_subnet.obj.results.0.ip_subnet.0.prefix.ip_addr.addr }}"
                  type: "{{ dns_vs_subnet.obj.results.0.ip_subnet.0.prefix.ip_addr.type }}"
                mask: "{{ dns_vs_subnet.obj.results.0.ip_subnet.0.prefix.mask }}"
          dns_info:
          - type: DNS_RECORD_A
            algorithm: DNS_RECORD_RESPONSE_CONSISTENT_HASH
            fqdn: "dns.{{ dns_service_domain }}"
          name: vsvip-DNS-VS-Default-Cloud
      register: vsvip_results

    - name: Create DNS Virtual Service
      avi_api_session:
        avi_credentials: "{{ avi_credentials }}"
        http_method: post
        path: "virtualservice"
        tenant: "admin"
        data:
          name: DNS-VS
          enabled: true
          analytics_policy:
            full_client_logs:
              enabled: true
              duration: 30
              throttle: 10
            client_insights: NO_INSIGHTS
            all_headers: false
            metrics_realtime_update:
              enabled: true
              duration: 30
            udf_log_throttle: 10
            significant_log_throttle: 10
            learning_log_policy:
              enabled: false
            client_log_filters: []
            client_insights_sampling: {}
          enable_autogw: true
          weight: 1
          delay_fairness: false
          max_cps_per_client: 0
          limit_doser: false
          type: VS_TYPE_NORMAL
          use_bridge_ip_as_vip: false
          flow_dist: LOAD_AWARE
          ign_pool_net_reach: false
          ssl_sess_cache_avg_size: 1024
          remove_listening_port_on_vs_down: false
          close_client_conn_on_config_update: false
          bulk_sync_kvcache: false
          advertise_down_vs: false
          scaleout_ecmp: false
          active_standby_se_tag: ACTIVE_STANDBY_SE_1
          flow_label_type: NO_LABEL
          content_rewrite:
            request_rewrite_enabled: false
            response_rewrite_enabled: false
            rewritable_content_ref: /api/stringgroup?name=System-Rewritable-Content-Types
          sideband_profile:
            sideband_max_request_body_size: 1024
          use_vip_as_snat: false
          traffic_enabled: true
          allow_invalid_client_cert: false
          vh_type: VS_TYPE_VH_SNI
          application_profile_ref: /api/applicationprofile?name=System-DNS
          network_profile_ref: /api/networkprofile?name=System-UDP-Per-Pkt
          analytics_profile_ref: /api/analyticsprofile?name=System-Analytics-Profile
          %{ if configure_gslb && create_gslb_se_group }
          se_group_ref: "{{ gslb_se_group.obj.url }}"
          %{ endif}
          cloud_ref: "{{ avi_cloud.obj.url }}"
          services:
          - port: 53
            port_range_end: 53
            enable_ssl: false
            enable_http2: false
          - port: 53
            port_range_end: 53
            override_network_profile_ref: /api/networkprofile/?name=System-TCP-Proxy
            enable_ssl: false
            enable_http2: false
          vsvip_ref: "{{ vsvip_results.obj.url }}"
          vs_datascripts: []
      register: dns_vs

    - name: Add DNS-VS to System Configuration
      avi_systemconfiguration:
        avi_credentials: "{{ avi_credentials }}"
        avi_api_update_method: patch
        avi_api_patch_op: add
        tenant: admin
        dns_virtualservice_refs: "{{ dns_vs.obj.url }}"
%{ endif ~} 
%{ if configure_gslb && gslb_site_name != "" ~}
    - name: GSLB Config | Verify Cluster UUID
      avi_api_session:
        avi_credentials: "{{ avi_credentials }}"
        http_method: get
        path: cluster
      register: cluster
    - name: Create GSLB Config
      avi_gslb:
        avi_credentials: "{{ avi_credentials }}"
        name: "GSLB"
        sites:
          - name: "{{ gslb_site_name }}"
            username: "{{ username }}"
            password: "{{ password }}"
            ip_addresses:
              - type: "V4"
                addr: "{{ controller_ip[0] }}"
%{ if controller_ha ~}
              - type: "V4"
                addr: "{{ controller_ip[1] }}"
              - type: "V4"
                addr: "{{ controller_ip[2] }}"
%{ endif ~}
            enabled: True
            member_type: "GSLB_ACTIVE_MEMBER"
            port: 443
            dns_vses:
              - dns_vs_uuid: "{{ dns_vs.obj.uuid }}"
            cluster_uuid: "{{ cluster.obj.uuid }}"
        dns_configs:
          %{ for domain in gslb_domains }
          - domain_name: "${domain}"
          %{ endfor }
        leader_cluster_uuid: "{{ cluster.obj.uuid }}"
      register: gslb_results
    - name: Display gslb_results
      ansible.builtin.debug:
        var: gslb_results
  %{ endif }
  %{ if configure_gslb_additional_sites }%{ for site in additional_gslb_sites }

    - name: GSLB Config | Verify Remote Site is Ready
      avi_api_session:
        controller: "${site.ip_address_list[0]}"
        username: "admin"
        password: "{{ password }}"
        api_version: ${avi_version}
        http_method: get
        path: virtualservice?name=DNS-VS
      until: remote_site_check is not failed
      retries: 30
      delay: 10
      register: remote_site_check

    - name: GSLB Config | Verify DNS configuration
      avi_api_session:
        controller: "${site.ip_address_list[0]}"
        username: "admin"
        password: "{{ password }}"
        api_version: ${avi_version}
        http_method: get
        path: virtualservice?name=DNS-VS
      until: dns_vs_verify is not failed
      failed_when: dns_vs_verify.obj.count != 1
      retries: 30
      delay: 10
      register: dns_vs_verify

    - name: Display DNS VS Verify
      ansible.builtin.debug:
        var: dns_vs_verify

    - name: GSLB Config | Verify GSLB site configuration
      avi_api_session:
        avi_credentials: "{{ avi_credentials }}"
        http_method: post
        path: gslbsiteops/verify
        data:
          name: name
          username: admin
          password: "{{ password }}"
          port: 443
          ip_addresses:
            - type: "V4"
              addr: "${site.ip_address_list[0]}"
      register: gslb_verify
      
    - name: Display GSLB Siteops Verify
      ansible.builtin.debug:
        var: gslb_verify

    - name: Add GSLB Sites
      avi_api_session:
        avi_credentials: "{{ avi_credentials }}"
        http_method: patch
        path: "gslb/{{ gslb_results.obj.uuid }}"
        tenant: "admin"
        data:
          add:
            sites:
              - name: "${site.name}"
                member_type: "GSLB_ACTIVE_MEMBER"
                username: "{{ username }}"
                password: "{{ password }}"
                cluster_uuid: "{{ gslb_verify.obj.rx_uuid }}"
                ip_addresses:  
%{ for address in site.ip_address_list ~}
                  - type: "V4"
                    addr: "${address}"
%{ endfor ~}
                dns_vses:
                  - dns_vs_uuid: "{{ dns_vs_verify.obj.results.0.uuid }}"
  %{ endfor }%{ endif }%{ endif ~}
%{ if controller_ha }
    - name: Configure Cluster Credentials
      avi_api_session:
        avi_credentials: "{{ avi_credentials }}"
        http_method: post
        path: "clusterclouddetails"
        tenant: "admin"
        data:
          name: "azure"
          azure_info:
            subscription_id: "{{ subscription_id }}"
            cloud_credential_ref: "/api/cloudconnectoruser?name=azure"

    - name: Controller Cluster Configuration
      avi_cluster:
        avi_credentials: "{{ avi_credentials }}"
        state: present
        nodes:
            - name:  "{{ controller_names[0] }}" 
              password: "{{ password }}"
              ip:
                type: V4
                addr: "{{ controller_ip[0] }}"
            - name:  "{{ controller_names[1] }}" 
              password: "{{ password }}"
              ip:
                type: V4
                addr: "{{ controller_ip[1] }}"
            - name:  "{{ controller_names[2] }}" 
              password: "{{ password }}"
              ip:
                type: V4
                addr: "{{ controller_ip[2] }}"
        name: "cluster01"
        tenant_uuid: "admin"
%{ endif }