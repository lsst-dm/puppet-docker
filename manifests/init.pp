# docker
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
# Parameters
#   required_pkgs 
#     list of package names, see module level hiera, these are OS dependant
#   service_name
#     Name of service, see module level hiera, possibly unique per OS
#   yumrepo_data
#     Hash of puppet yumrepo keys and values
#     Keys must be valid attribute names of the puppet yumrepo resource
#
# @example
#   include docker
#
#
# TODO Why aren't we using https://forge.puppet.com/garethr/docker
#
# TODO see also:
# https://www.puppetcookbook.com/posts/install-basic-docker-daemon.html
#
class docker (
    Array[String,1]       $required_pkgs,
    String                $service_name,
    Hash[String,String,1] $yumrepo_data,
) {

    yumrepo { 'dockerrepo' :
        ensure => 'present',
        descr  => 'Docker Yum Repository',
        *      => $yumrepo_data,
    }

    # Required packages
    ensure_packages( $required_pkgs )

    # SERVICE
    service { $service_name :
        ensure     => running,
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        require    => [
            Package[$required_pkgs],
        ],
    }

}
