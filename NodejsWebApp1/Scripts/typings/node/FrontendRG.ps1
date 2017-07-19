$frontendrg = "Frontend-P2-RG"
$loc = "West Europe"
$vnetname = "bg1vnet"
# Creating Front End Resource Group
New-AzureRmResourceGroup -Name $frontendrg -Location $loc -Force;

$subnetMain = New-AzureRmVirtualNetworkSubnetConfig -Name "main" -AddressPrefix 10.0.0.0/24
$subnetGreen = New-AzureRmVirtualNetworkSubnetConfig -Name "green" -AddressPrefix 10.0.1.0/24
$subnetAppGW = New-AzureRmVirtualNetworkSubnetConfig -Name "appgw" -AddressPrefix 10.0.2.0/24
$subnetBlue = New-AzureRmVirtualNetworkSubnetConfig -Name "blue" -AddressPrefix 10.0.3.0/24

$vnet = New-AzureRmVirtualNetwork -Name $vnetname -ResourceGroupName $frontendrg -Location $loc -AddressPrefix 10.0.0.0/8 -Subnet $subnetGreen,$subnetMain,$subnetAppGW,$subnetBlue

$subnetGreen=$vnet.Subnets[0]
$subnetMain=$vnet.Subnets[1]
$subnetAppGW=$vnet.Subnets[2]
$subnetBlue=$vnet.Subnets[3]

$publicip = New-AzureRmPublicIpAddress -ResourceGroupName $frontendrg -name publicIP01 -location $loc -AllocationMethod Dynamic
$gipconfig = New-AzureRmApplicationGatewayIPConfiguration -Name gatewayIP01 -Subnet $subnetAppGW

$pool = New-AzureRmApplicationGatewayBackendAddressPool -Name pool01 -BackendIPAddresses 10.0.0.5

$poolSetting01 = New-AzureRmApplicationGatewayBackendHttpSettings -Name "besetting01" -Port 80 -Protocol Http -CookieBasedAffinity Disabled -RequestTimeout 120

$fp = New-AzureRmApplicationGatewayFrontendPort -Name frontendport01  -Port 80

$fipconfig = New-AzureRmApplicationGatewayFrontendIPConfig -Name fipconfig01 -PublicIPAddress $publicip

$listener = New-AzureRmApplicationGatewayHttpListener -Name listener01 -Protocol Http -FrontendIPConfiguration $fipconfig -FrontendPort $fp

$rule = New-AzureRmApplicationGatewayRequestRoutingRule -Name rule01 -RuleType Basic -BackendHttpSettings $poolSetting01 -HttpListener $listener -BackendAddressPool $pool

$sku = New-AzureRmApplicationGatewaySku -Name Standard_Small -Tier Standard -Capacity 2

$appgw = New-AzureRmApplicationGateway -Name bgappgw -ResourceGroupName $frontendrg -Location $loc -BackendAddressPools $pool -BackendHttpSettingsCollection $poolSetting01 -FrontendIpConfigurations $fipconfig  -GatewayIpConfigurations $gipconfig -FrontendPorts $fp -HttpListeners $listener -RequestRoutingRules $rule -Sku $sku
