# docker::sync_ldap_users
#
# Sync users from an LDAP group to the local group "docker"
#
# Parameters
#   required_pkgs
#       Type: Array of Strings
#       Package names (possibly OS dependant) to provide:
#           + /usr/bin/ldapsearch
#   ldapsearch_cmd
#   ldapsearch_opts
#   ldapsearch_host
#   ldapsearch_dnbase
#   ldapsearch_query
#   ldapsearch_field
#       Type: String
#       Used to build ldap query in the form:
#       $ldapsearch_cmd $ldapsearch_opts -H $ldapsearch_host -b $ldapsearch_base $query $field
#
# @summary Sync users from an LDAP group to the local group "docker"
#
# @example
#   include docker::sync_ldap_users
class docker::sync_ldap_users (
    Array[String,1] $required_pkgs,
    String          $ldapsearch_cmd,
    String          $ldapsearch_opts,
    String          $ldapsearch_host,
    String          $ldapsearch_dnbase,
    String          $ldapsearch_query,
    String          $ldapsearch_field,
) {

    # Resource defaults
    Cron {
        ensure => absent,
        user   => root,
        minute => '*',
        hour   => '*',
        month  => '*',
        monthday => '*',
        weekday  => '*',
    }

    # Needed by sync_ldap_users cron script
    ensure_packages( $required_pkgs )

    # Ensure directory for cron scripts
    $dir_names = [ '/root/cron' ]
    $settings = {
        'ensure' => 'directory',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0700',
    }
    ensure_resource( 'file', $dir_names, $settings )

    # sync docker group with lsst_data ldap group
    $template_data = {
        'ldapsearch_cmd'    => $ldapsearch_cmd,
        'ldapsearch_opts'   => $ldapsearch_opts,
        'ldapsearch_host'   => $ldapsearch_host,
        'ldapsearch_dnbase' => $ldapsearch_dnbase,
        'ldapsearch_query'  => $ldapsearch_query,
        'ldapsearch_field'  => $ldapsearch_field,
    }
    file { '/root/cron/sync_ldap_users':
        ensure  => 'file',
        content => epp( 'docker/sync_ldap_users.epp', $template_data ),
        owner   => 'root',
        group   => 'root',
        mode    => '0500',
        require => [
            File[ $dir_names ],
        ],
    }
    cron { 'sync_ldap_users':
        command => '/root/cron/sync_ldap_users',
        user    => 'root',
        minute  => '*/15',
        require => [
            File['/root/cron/sync_ldap_users'],
        ],
    }

}
