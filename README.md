
# 1. OPENSHIFT (release 3.11)

**Referências:**

- https://github.com/openshift/openshift-ansible/tree/release-3.11
- https://docs.okd.io/3.11/install/index.html#multi-masters-using-native-ha-colocated
- https://docs.okd.io/3.11/install/prerequisites.html
- https://docs.okd.io/3.11/install/host_preparation.html
- https://docs.okd.io/3.11/install/prerequisites.html

##### 1.1 Planjamento da instalação do cluster:

Nesta abordagem iremos utilizar o cenário: Multiple masters using native HA 

Host | IP |Componente de Infra 
---------|-------|---------
master1.xpto |10.1.0.191| Master (clustered using native HA) and node and clustered etcd
master2.xpto | 10.1.0.192 | Master and node and clustered etcd
master3.xpto | 10.1.0.193 | Master and node and clustered etcd
infra-node1.xpto | 10.1.0.194 | HAProxy to load balance API master endpoints
infra-node2.xpto | 10.1.0.195 | HAProxy to load balance API master endpoints
node1.xpto | 10.1.0.196| Node
node2.xpto | 10.1.0.197| Node
lb.xpto | 10.1.0.198| HAProxy to load balance API master endpoints

**Importante:** Verificar os pré-requisitos de configurações das vm's.

# 2. ANSIBLE

A instalação do OKD será realizada via playbook, conforme documentação:
- https://github.com/openshift/openshift-ansible/tree/release-3.11

##### 2.1 ANSIBLE HOST:

Utilizaremos um host ansible para configuração dos nodes e implantação do cluster OKD.

HOST | IP | 
----|----
 ansible.xpto | 10.1.0.33

##### 2.2 PROCEDIMENTOS:

**2.2.3 Pré-requisitos:**

Com intuito de agilizar a preparação do ambiente, abaixo segue um link para download de um shellscript com a instalação dos pacotes listados como pré-requisitos bem como as configurações iniciais.
Também fornecemos um playbook que irá efetuar a copia e a instalação do script em todos os nodes:

**Observação importantes antes de executar script**: 
- A interface de rede nos servidores utilizados nesta abordagem ficou: **"ifcfg-ens160"**. (Verifique a nomeclatura da sua interface para efetuar a alteração caso necessário).
- Configure o volume descrito no ítem **2.2.4.2** 
- Configurar as entradas de DNS: **2.2.3.1.6** 


[Download Shellscript](https://raw.githubusercontent.com/ederqueirozdf/cluster-okd/master/prereqs-script.sh) - Script com pacotes e configurações de pré-requisitos
[Download Playbook Ansible](https://raw.githubusercontent.com/ederqueirozdf/cluster-okd/master/playbook-prereqs.yml) - Para executação do script via ansible

Partindo do principio de que você já tenha um host ansible configurado, faça o download do script e do playbook acima e execute o seguinte comando:

    # ansible-playbook playbook-prereqs.yml

- - -

Se você optou por utilizar os scripts acima, prossiga para o **ítem 2.3.**

Caso contrário segue documentação para configuração manual em cada host abaixo:
- - -

**2.2.3.1 - Pré requisitos e Preparação dos hosts:**

**Fonte desta seção:**
- https://docs.okd.io/3.11/install/host_preparation.html
- https://docs.okd.io/3.11/install/prerequisites.html


(For RHEL 7 systems)

**2.2.3.1.1 - Instalação dos pacotes necessários**

    # yum install wget git net-tools bind-utils yum-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct
    # yum update
    # reboot

**2.2.3.1.2 - Instale os pacotes necessários para o método de instalação (neste processo utilizaremos o ansible):**

    # yum -y install \
        https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

**2.2.3.1.3 - Desative o repositório EPEL global:**

    # sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo

**2.2.3.1.4 - Requerimentos SELinux**

O SELINUX deve estar ativado em todos os servidores antes de instalar o OKD.(SELINUX=enforcing) e (SELINUXTYPE=targeted).

    # This file controls the state of SELinux on the system.
    # SELINUX= can take one of these three values:
    #     enforcing - SELinux security policy is enforced.
    #     permissive - SELinux prints warnings instead of enforcing.
    #     disabled - No SELinux policy is loaded.
    SELINUX=enforcing
    # SELINUXTYPE= can take one of these three values:
    #     targeted - Targeted processes are protected,
    #     minimum - Modification of targeted policy. Only selected processes are protected.
    #     mls - Multi Level Security protection.
    SELINUXTYPE=targeted

**2.2.3.1.5 - Instale os pacotes para Ansible:**

    # yum -y --enablerepo=epel install ansible pyOpenSSL

**2.2.3.1.6 - Requisitos de DNS**

O OKD requer um servidor DNS totalmente funcional no ambiente. Verifique nas interfaces se a opção **NM_CONTROLLED** está definida com yes.

    NM_CONTROLLED=yes

Da mesma forma, o parâmetro **PEERDNS** deve estar habilitado para que sejam gerados os arquivos de dnsmasq.

    PEERDNS = yes

Verifique se cada host do seu ambiente está configurado para resolver nomes de host do seu servidor DNS:

Configure os registros TIPO "A" no seu DNS:

    srv91.xpto      A    10.1.0.191
    srv92.xpto      A    10.1.0.192
    srv93.xpto      A    10.1.0.193
    srv94.xpto      A    10.1.0.194
    srv95.xpto      A    10.1.0.195
    srv96.xpto      A    10.1.0.196
    srv97.xpto      A    10.1.0.197
    srv98.xpto      A    10.1.0.198

**2.2.4 - Docker**

**2.2.4.1 - Instalação Docker**

    yum install docker-1.13.1

**2.2.4.2 - Volume Docker**

O uso de um volume dedicado para o armazenamento do docker é recomendado no ítem de prepação dos hosts. Para isso, é necessário a entrega de um disco para os hosts que farão parte do cluster OKD.

Ao realizar a entrega do novo disco aos hosts, execute o comando abaixo para escanear e reconhecer o novo "device" de disco entregue: *(faça isso em todos os nodes do cluster)*

    echo "- - -" > /sys/class/scsi_host/host0/scan

Confirme se o disco tornou-se reconhecido na vm com o comando:

    fdisk -l 

O resultado deve ser algo parecido como:

    Disk /dev/sdb: 107.4 GB, 107374182400 bytes, 209715200 sectors
    Units = sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes

O novo disco será configurado através do script "docker-storage-setup" a ser entregue para o armazenamento de containers docker.

*Nesta abordagem foi atribuído à partição **/dev/sdb** ao disco entregue.*

**2.2.4.3 - Configuração Storage-Pool Docker**

    cat <<EOF > /etc/sysconfig/docker-storage-setup
    DEVS=/dev/sdb
    VG=docker-vg
    EOF

Execute o docker-storage-setup e revise a saída para garantir que o volume do docker-pool foi criado:

    # docker-storage-setup

Finalizado o setup, verifique as configurações:

O lvs listará na forma sumário os volumes lógicos no seu host.

    # cat /etc/sysconfig/docker-storage
    # lvs

Exemplo:

    lvs
    LV          VG        Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
    docker-pool docker-vg twi-aot--- 39,79g             8,30   11,19                           
    home        vol       -wi-ao---- <3,00g                                                    
    root        vol       -wi-ao---- 36,00g                                                    
    tmp         vol       -wi-ao---- 10,00g                                                    
    var         vol       -wi-ao---- 50,00g 

Também pode validar listando o sumário de Grupos de volumes:

    # vgs

Exemplo:

    vgs
    VG        #PV #LV #SN Attr   VSize    VFree 
    docker-vg   1   1   0 wz--n- <100,00g 60,00g
    vol         1   4   0 wz--n-  <99,00g     0 

Perceba que o script docker-storage-setup criou um grupo de volume (docker-vg) e criou um volume lógico com 40GB (docker-pool).

Por fim, inicialize os serviços de docker, e configure para inicializar com o sistema:

    # systemctl enable docker
    # systemctl start docker
    # systemctl is-active docker

**Importante lembrar**: As ações de pré-requisitos e preparação do host devem ser executados em todos os hosts que irão compor o cluster OKD.

##### 2.3 INVENTÁRIO DE CONFIGURAÇÃO - OKD:

O inventário de configuração do cluster OKD, é basicamente a receita de bolo a ser seguida para a implantação do cluster. Os playbooks de instalação fazem a leitura do seu arquivo de inventário para saber onde e como instalar o OKD na sua estrutura.

**Fontes desta seção:**
- https://docs.okd.io/3.11/install/configuring_inventory_file.html
- https://docs.okd.io/3.11/install/example_inventories.html#install-config-example-inventories


**Clone o repositório  openshift/openshift-ansible, que fornece os playbooks e os arquivos de configuração necessários:**

    # cd ~
    # git clone https://github.com/openshift/openshift-ansible
    # cd openshift-ansible
    # git checkout release-3.11

Você encontra exemplos de arquivos de invetário aqui: https://docs.okd.io/3.11/install/example_inventories.html#install-config-example-inventories

**Inventário**
Inicialmente nosso invetário ficará da seguinte forma:

    # vim inventario-okd

cole o arquivo:

        # Create an OSEv3 group that contains the master, nodes, etcd, and lb groups.
        # The lb group lets Ansible configure HAProxy as the load balancing solution.
        # Comment lb out if your load balancer is pre-configured.
        [OSEv3:children]
        masters
        nodes
        etcd
        lb

        # Set variables common for all OSEv3 hosts
        [OSEv3:vars]
        ansible_ssh_user=root
        openshift_deployment_type=origin
        openshift_master_default_subdomain=cloudapps.xpto

        # uncomment the following to enable htpasswd authentication; defaults to AllowAllPasswordIdentityProvider
        #openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider'}]

        # Native high availability cluster method with optional load balancer.
        # If no lb group is defined installer assumes that a load balancer has
        # been preconfigured. For installation the value of
        # openshift_master_cluster_hostname must resolve to the load balancer
        # or to one or all of the masters defined in the inventory if no load
        # balancer is present.
        openshift_master_cluster_method=native
        openshift_master_cluster_hostname=srv98
        openshift_master_cluster_public_hostname=okd.xpto

        # host group for masters
        [masters]
        srv91
        srv92
        srv93

        # host group for etcd
        [etcd]
        srv91
        srv92
        srv93

        # Specify load balancer host
        [lb]
        srv98

        # host group for nodes, includes region info
        [nodes]
        srv91 openshift_node_group_name='node-config-master'
        srv92 openshift_node_group_name='node-config-master'
        srv93 openshift_node_group_name='node-config-master'
        srv94 openshift_node_group_name='node-config-infra'
        srv95 openshift_node_group_name='node-config-infra'
        srv96 openshift_node_group_name='node-config-compute'
        srv97 openshift_node_group_name='node-config-compute'

A única linha que adicionamos neste primeiro momento diferente do arquivo de exemplo que é fornecido:

        openshift_master_default_subdomain=cloudapps.xpto

Essa variável substitui o subdomínio padrão a ser usado para rotas dentro do cluster okd.

Para mais configurações específicas é possível consultar as variáveis de configuração do cluster OKD:
- https://docs.okd.io/3.11/install/configuring_inventory_file.html#configuring-cluster-variables

##### 2.3.1 VALIDAÇÃO DE INVENTÁRIO - OKD:

O Openshift-ansible oferece um script de pré-requisitos para validação das configurações do seu cluster. SEndo assim, antes de realizar o deploy no ambiente, iremos executar o playbook de validação:

    # ansible-playbook -v --key-file /etc/keys/key.pem -i inventario-okd playbooks/prerequisites.yml

Ao final da execução do comando acima, será possível identificar o status da sua "instalação", será possível ver algo como a imagem abaixo:

![Preview Status](https://github.com/ederqueirozdf/cluster-okd/blob/master/preview-status.png)


##### 2.4 DEPLOY CLUSTER - OKD:

**Fonte desta seção:**
- https://docs.okd.io/3.11/install/running_install.html

Para realizar o deploy, execute o playbook:

    # ansible-playbook -v --key-file /etc/keys/key.pem -i inventario-okd playbooks/deploy_cluster.yml

Se tudo der certo, você terá resumo do status parecido com:

![Deploy Status](https://github.com/ederqueirozdf/cluster-okd/blob/master/deploy-status.png)


Agora, você poderá acessar o ambiente através da URL declarada no inventario:

- https://okd.xpto:8443


**Dica:** Neste cenário teremos apenas o usuário admin com qualquer senha, para ter visão de todos os projetos pelo usuário admin, acesse um node master e execute o comando:

    oc adm policy add-cluster-role-to-user admin admin

![Tela OKD](https://github.com/ederqueirozdf/cluster-okd/blob/master/login-okd.png)
