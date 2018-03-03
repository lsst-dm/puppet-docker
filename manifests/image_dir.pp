# docker::image_dir
#
# SETUP ALTERNATE DOCKER IMAGE INSTALL DIRECTORY
#
# Parameters
#   path
#       type=String
#       absolute path to alternate image install directory
#       Default: no default value, value must be specified if this class is included
#   owner
#       type=String
#       username for unix perms of alternate image install directory
#       Default: root
#   group
#       type=String
#       groupname for unix perms of alternate image install directory
#       Default: root
#   mode
#       type=String
#       Three digit mode for unix perms of alternate image install directory
#       Default: 770
#   requires_mountpoint
#       type=Boolean
#       If true, then parameter mountpoint_data must be defined
#       Default: False
#   mountpoint_data
#       type=Hash[String,String,4]
#       OPTIONAL. Required only if requires_mountpoint=True
#       Keys must be valid parameters for the Mount Mount resource type
#
# @summary Setup alternate docker image install directory
#
# @example
#   include docker::image_dir
class docker::image_dir (
    String  $path,
    String  $owner,
    String  $group,
    String  $mode,
    Boolean $requires_mountpoint,
) {

    # enforce that docker resources are realized before this class runs
    require ::docker

    # Create mount resource for required_mountpoint
    if $requires_mountpoint {
        $mount_params = lookup(
            'docker::image_dir::mountpoint_data',
            Hash[String,String,4],
            'first'
        )
        $mountpoint = $mount_params['name']
        $mp_dir_params = {
            'ensure' => 'directory',
            'owner'  => 'root',
            'group'  => 'root',
            'mode'   => '0755',
        }
        # Ensure mountpoint dir exists
        ensure_resource( 'file', $mountpoint, $mp_dir_params )
        # Ensure mountpoint is mounted
        ensure_resource( 'mount', $mountpoint, $mount_params )
        # Setup mountpoint as requirement for path (below)
        $path_requires = [ Mount[ $mountpoint ] ]
    }
    else {
        # No mountpoint, setup empty requirements for path (below)
        $mountpoint = ''
        $path_requires = []
    }
    $path_require = $path_requires

    # Ensure parents of target dir exist
    $parent_dir_settings = {
        'ensure' => 'directory',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0700',
    }
#    notify{ 'PATH' : message => $path }
#    notify{ 'MOUNTPOINT' : message => $mountpoint }
    $mp_size = size( $mountpoint )
#    notify{ "mp_size: ${mp_size}" : }
    $path_size = size( $path )
#    notify{ "path_size: ${path_size}" : }
    $dirparts = reject( split( $path[$mp_size,$path_size], '/' ) , '^$' )
#    notify{ "DIR PARTS..." : }
#    each( $dirparts ) |$d| { notify{ $d : } }
    $numparts = size( $dirparts )
#    notify{ 'numparts' : message => $numparts }
    if ( $numparts > 1 ) {
#        notify{ 'PARENTS:...' : }
        each( Integer[2,$numparts] ) |$i| {
            $p = reduce( Integer[2,$i], $path ) |$m,$v| { dirname( $m ) }
#            notify{ $i : message => $p }
            ensure_resource( 'file', $p, $parent_dir_settings )
        }
    }

    # DIRECTORY
    file { $path :
        ensure  => 'directory',
        owner   => $owner,
        group   => $group,
        mode    => $mode,
        require => $path_require
    }

    # Adjust INI config
    ini_setting { 'docker_image_dir':
        ensure            => present,
        path              => '/usr/lib/systemd/system/docker.service',
        section           => 'Service',
        key_val_separator => '=',
        setting           => 'ExecStart',
        value             => "/usr/bin/dockerd --graph ${path}",
        require           => File[ $path ],
# Leaving the notify below causes:
#   Error: Failed to apply catalog: Found 1 dependency cycle:
#   (File[/qserv/docker] => Ini_setting[docker_image_dir] =>
#   Service[docker] => Class[Docker] => Class[Docker::Image_dir] =>
#   File[/qserv/docker])
#        notify            => Service[ $::docker::service_name ],
    }

# lint:ignore:140chars
#    # IF /qserv/docker IS EMPTY
#    exec { "sync_docker_image_storage":
#        path    => ["/usr/bin", "/usr/sbin"],
#        onlyif  => "find /qserv/docker -maxdepth 0 -empty -exec echo {} is empty. \; | grep empty",
#        command => "systemctl stop docker && rsync -aq /var/lib/docker/ /qserv/docker/ && systemctl start docker && rm -fr /var/lib/docker/* ",
#        timeout => 3600,
##        notify => Extra::Docker::Service['docker'],
#        require => [ 
#                     Ini_setting['docker_image_dir'],
#                   ]
#    }
# lint:endignore

}
