

#Creates a resource group with a load balancer inside which has a frontend private ip address. In the end of this section this script also creates a vm scale set.



$greenrg = "Green-P-RG" #This needs to be be changed with every new deployment
$frontendrg = "Frontend-P1-RG"
$loc = "West Europe"
$vnetname = "bgvnet"
$LBFrontendNewPrivateIPAddress = "10.0.0.5" #This is the frontend IP address of the load balancer and should be changed with every new deployment and should be in the same range as the main subnet
$vmssName = 'coevmssgreenbg'; #This has to be a unique name and needs to be changed with every new deployment
$imageuri = "https://imagestor123.blob.core.windows.net/vhdimagecontainer/Win2012R2.vhd" #This has to be a new image URI with every new deployment


#Specify VMSS Specific Details
$adminUsername = 'demouser';
$adminPassword = "P@ssw0rd12345";

$PublisherName = 'MicrosoftWindowsServer'
$Offer         = 'WindowsServer'
$Sku          = '2012-R2-Datacenter'
$Version       = 'latest'
$vmNamePrefix = 'winvmss'

#Add an Extension
$extname = 'BGInfo';
$publisher = 'Microsoft.Compute';
$exttype = 'BGInfo';
$extver = '2.1';

#Specify Number of Nodes
$numberofnodes = 2

$backendSubnetName = "green"

New-AzureRmResourceGroup -Name $greenrg -Location $loc -Force;

$vnet= Get-AzureRmVirtualNetwork -Name $vnetname -ResourceGroupName $frontendrg

$subnetMain = Get-AzureRmVirtualNetworkSubnetConfig -Name "green" -VirtualNetwork $vnet

$subnetMain = $vnet.Subnets[1]

$frontendIP = New-AzureRmLoadBalancerFrontendIpConfig -Name LB-Frontend -PrivateIpAddress $LBFrontendNewPrivateIPAddress -SubnetId $vnet.subnets[1].Id

$beaddresspool= New-AzureRmLoadBalancerBackendAddressPoolConfig -Name "LB-backend"

$inboundNATRule1= New-AzureRmLoadBalancerInboundNatRuleConfig -Name "RDP" -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort 3389 -BackendPort 3389

$healthProbe = New-AzureRmLoadBalancerProbeConfig -Name "HealthProbe" -RequestPath "index.html" -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2

$lbrule = New-AzureRmLoadBalancerRuleConfig -Name "HTTP" -FrontendIpConfiguration $frontendIP -BackendAddressPool $beAddressPool -Probe $healthProbe -Protocol Tcp -FrontendPort 80 -BackendPort 80

$nrplb = New-AzureRmLoadBalancer -ResourceGroupName $greenrg -Name "NRP-LB" -Location $loc -FrontendIpConfiguration $frontendIP -InboundNatRule $inboundNATRule1 -LoadBalancingRule $lbrule -BackendAddressPool $beAddressPool -Probe $healthProbe

$backendSubnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $backendSubnetName -VirtualNetwork $vnet

$backendnic1= New-AzureRmNetworkInterface -ResourceGroupName $greenrg -Name lb-nic1-be -Location $loc -Subnet $backendSubnet -LoadBalancerBackendAddressPool $nrplb.BackendAddressPools[0] -LoadBalancerInboundNatRule $nrplb.InboundNatRules[0]

#The code below creates a vm scale set

$vnet= Get-AzureRmVirtualNetwork -Name $vnetname -ResourceGroupName $frontendrg

$ILB = Get-AzureRmLoadBalancer -Name "NRP-LB" -ResourceGroupName $greenrg

$backendSubnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $backendSubnetName -VirtualNetwork $vnet

$subnetId = (Get-AzureRmVirtualNetworkSubnetConfig -Name $backendSubnetName -VirtualNetwork $vnet).Id

$vmssipconf_ILB_BEAddPools = $ILB.BackendAddressPools[0].Id

$ipCfg = New-AzureRmVmssIPConfig -Name 'nic' -LoadBalancerBackendAddressPoolsId $vmssipconf_ILB_BEAddPools -SubnetId $subnetId;

$vmss = New-AzureRmVmssConfig -Location $loc -SkuCapacity $numberofnodes -SkuName 'Standard_DS1' -UpgradePolicyMode 'automatic' `
| Add-AzureRmVmssNetworkInterfaceConfiguration -Name $backendSubnet -Primary $true -IPConfiguration $ipCfg `
| Set-AzureRmVmssOSProfile -ComputerNamePrefix $vmNamePrefix -AdminUsername $adminUsername -AdminPassword $adminPassword `
| Set-AzureRmVmssStorageProfile -Name "test" -OsDiskCreateOption 'FromImage' -OsDiskCaching ReadWrite -OsDiskOsType Windows -Image $imageuri `
| Add-AzureRmVmssExtension -Name $extname -Publisher $publisher -Type $exttype -TypeHandlerVersion $extver -AutoUpgradeMinorVersion $true

New-AzureRmVmss -ResourceGroupName $greenrg -Name $vmssName -VirtualMachineScaleSet $vmss -Verbose;