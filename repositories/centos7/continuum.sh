#!/bin/bash

# VM requirement
# - CentOS 7.0
# - 2GB of RAM is recommended
#
# curl -sS https://raw.githubusercontent.com/chonla/continuum/master/repositories/centos7/continuum.sh | sudo bash

HOST_NAME=continuum
GITLAB_DOMAIN=${HOST_NAME}.ar-bro.net
GITLAB_PORT=8888
GITLAB_URL=http://${GITLAB_DOMAIN}:${GITLAB_PORT}/
JENKINS_PORT=8081

set_host_name ()
{
    echo "Setting up hostname: ${HOST_NAME}"
    hostname ${HOST_NAME}
    hostnamectl set-hostname ${HOST_NAME}
}

install_tools ()
{
    echo "Install Tools"
    wget https://raw.githubusercontent.com/chonla/continuum/master/tools/inied.php.txt -O /tmp/inied.php
    mkdir ~/continuum_toolbox/
    mv /tmp/inied.php ~/continuum_toolbox/
}

install_php_7 ()
{
    echo "Installing PHP 7"
    sudo rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    sudo rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
    sudo yum install -y php70w php70w-opcache php70w-mbstring php70w-mcrypt
}

install_git_lab ()
{
    echo "Installing GitLab"
    sudo yum install -y curl policycoreutils openssh-server openssh-clients
    sudo systemctl enable sshd
    sudo systemctl start sshd
    sudo yum install -y postfix
    sudo systemctl enable postfix
    sudo systemctl start postfix
    sudo yum install -y firewalld
    systemctl unmask firewalld
    systemctl enable firewalld
    systemctl restart firewalld
    sudo firewall-cmd --permanent --add-service=http
    sudo firewall-cmd --permanent --add-port=${GITLAB_PORT}/tcp
    sudo systemctl reload firewalld
    curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh | sudo bash
    sudo yum install -y gitlab-ce
    sudo php ~/continuum_toolbox/inied.php /etc/gitlab/gitlab.rb external_url "'"${GITLAB_URL}"'" _SPACE_
    sudo gitlab-ctl reconfigure
    sudo gitlab-ctl restart
}

install_java ()
{
    echo "Installing Java"
    sudo yum install -y java
}

install_jenkins ()
{
    echo "Installing Jenkins"
    sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo
    sudo rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
    systemctl restart firewalld
    sudo firewall-cmd --permanent --add-service=http
    sudo firewall-cmd --permanent --add-port=${JENKINS_PORT}/tcp
    sudo systemctl reload firewalld
    sudo yum install -y jenkins
    sudo php ~/continuum_toolbox/inied.php /etc/sysconfig/jenkins JENKINS_PORT '"'${JENKINS_PORT}'"'
    sudo php ~/continuum_toolbox/inied.php /etc/sysconfig/jenkins JENKINS_JAVA_OPTIONS '"'-Djava.awt.headless=true_SPACE_-Djava.net.preferIPv4Stack=true'"'
    sudo chkconfig jenkins on
    systemctl start jenkins
}

show_jenkins_secret ()
{
    echo "Use the following secret to unlock Jenkins"
    while [ ! -f /var/lib/jenkins/secrets/initialAdminPassword ]; do sleep 1; done
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword
}

install_composer ()
{
    echo "Installing Composer"
    sudo php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    sudo php -r "if (hash_file('SHA384', 'composer-setup.php') === 'e115a8dc7871f15d853148a7fbac7da27d6c0030b848d9b3dc09e2a0388afed865e6a3d6b3c0fad45c48e2b5fc1196ae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    sudo php composer-setup.php
    sudo php -r "unlink('composer-setup.php');"
    sudo mv composer.phar /usr/local/bin/composer
}

main ()
{
    set_host_name
    install_php_7
    install_composer
    install_tools
    install_git_lab
    install_java
    install_jenkins
    show_jenkins_secret
}

main
