$loadEnvPath = Join-Path $PSScriptRoot 'loadEnv.ps1'
if (-Not (Test-Path -Path $loadEnvPath)) {
    $loadEnvPath = Join-Path $PSScriptRoot '..\loadEnv.ps1'
}
. ($loadEnvPath)
$TestRecordingFile = Join-Path $PSScriptRoot 'Get-AzsScaleUnitNode.Recording.json'
$currentPath = $PSScriptRoot
while(-not $mockingPath) {
    $mockingPath = Get-ChildItem -Path $currentPath -Recurse -Include 'HttpPipelineMocking.ps1' -File
    $currentPath = Split-Path -Path $currentPath -Parent
}
. ($mockingPath | Select-Object -First 1).FullName

Describe 'Get-AzsScaleUnitNode' {
    . $PSScriptRoot\Common.ps1

    BeforeEach {

        function ValidateScaleUnitNode {
            param(
                [Parameter(Mandatory = $true)]
                $ScaleUnitNode
            )

            $ScaleUnitNode          | Should Not Be $null

            # Resource
            $ScaleUnitNode.Id       | Should Not Be $null
            $ScaleUnitNode.Location | Should Not Be $null
            $ScaleUnitNode.Name     | Should Not Be $null
            $ScaleUnitNode.Type     | Should Not Be $null

            # Scale Unit Node
            $ScaleUnitNode.CanPowerOff          | Should Not Be $null
            $ScaleUnitNode.CapacityOfCores         | Should Not Be $null
            $ScaleUnitNode.CapacityOfMemoryInGB    | Should Not Be $null
            $ScaleUnitNode.PowerState           | Should Not Be $null
            $ScaleUnitNode.ScaleUnitName        | Should Not Be $null
            $ScaleUnitNode.ScaleUnitNodeStatus  | Should Not Be $null
            $ScaleUnitNode.ScaleUnitUri         | Should Not Be $null

			if($ScaleUnitNode.Gpu -ne $null)
			{
			    foreach ($Gpu in $ScaleUnitNode.Gpu)
				{
				    $Gpu.HostDriverVersion   | Should Not Be $null
				    $Gpu.Name                | Should Not Be $null
				    $Gpu.Oem                 | Should Not Be $null
				    $Gpu.PartitionSize       | Should Not Be $null
				    $Gpu.SlotLocation        | Should Not Be $null
				    $Gpu.Type                | Should Not Be $null
				}
			}
        }

        function AssertScaleUnitNodesAreSame {
            param(
                [Parameter(Mandatory = $true)]
                $Expected,

                [Parameter(Mandatory = $true)]
                $Found
            )
            if ($Expected -eq $null) {
                $Found | Should Be $null
            }
            else {
                $Found                  | Should Not Be $null

                # Resource
                $Found.Id               | Should Be $Expected.Id
                $Found.Location         | Should Be $Expected.Location
                $Found.Name             | Should Be $Expected.Name
                $Found.Type             | Should Be $Expected.Type

                # Scale Unit Node
                $Found.CanPowerOff          | Should Be $Expected.CanPowerOff
                $Found.CapacityOfCores      | Should Be $Expected.CapacityOfCores
                $Found.CapacityOfMemoryInGB | Should Be $Expected.CapacityOfMemoryInGB

                $Found.PowerState           | Should Be $Expected.PowerState
                $Found.ScaleUnitName        | Should Be $Expected.ScaleUnitName
                $Found.ScaleUnitNodeStatus  | Should Be $Expected.ScaleUnitNodeStatus
                $Found.ScaleUnitUri         | Should Be $Expected.ScaleUnitUri

				if($ScaleUnitNode.Gpu -ne $null)
			    {
					$ScaleUnitNode.Gpu.Count | Should Be $Expected.Gpu.Count
			    }
            }
        }
    }

    AfterEach {
        $global:Client = $null
    }


    It "TestListScaleUnitNodes" -Skip:$('TestListScaleUnitNodes' -in $global:SkippedTests) {
        $global:TestName = 'TestListScaleUnitNodes'

        $ScaleUnitNodes = Get-AzsScaleUnitNode -ResourceGroupName $global:ResourceGroupName -Location $global:Location
        $ScaleUnitNodes | Should Not Be $null
        foreach ($ScaleUnitNode in $ScaleUnitNodes) {
            ValidateScaleUnitNode -ScaleUnitNode $ScaleUnitNode
        }
    }


    It "TestGetScaleUnitNode" -Skip:$('TestGetScaleUnitNode' -in $global:SkippedTests) {
        $global:TestName = 'TestGetScaleUnitNode'

        $ScaleUnitNodes = Get-AzsScaleUnitNode -ResourceGroupName $global:ResourceGroupName -Location $global:Location
        foreach ($ScaleUnitNode in $ScaleUnitNodes) {
            $retrieved = Get-AzsScaleUnitNode -ResourceGroupName $global:ResourceGroupName -Location $global:Location -Name $ScaleUnitNode.Name
            AssertScaleUnitNodesAreSame -Expected $ScaleUnitNode -Found $retrieved
            break
        }
    }

    It "TestGetAllScaleUnitNodes" -Skip:$('TestGetAllScaleUnitNodes' -in $global:SkippedTests) {
        $global:TestName = 'TestGetAllScaleUnitNodes'

        $ScaleUnitNodes = Get-AzsScaleUnitNode -ResourceGroupName $global:ResourceGroupName -Location $global:Location
        foreach ($ScaleUnitNode in $ScaleUnitNodes) {
            $retrieved = Get-AzsScaleUnitNode -ResourceGroupName $global:ResourceGroupName -Location $global:Location -Name $ScaleUnitNode.Name
            AssertScaleUnitNodesAreSame -Expected $ScaleUnitNode -Found $retrieved
        }
    }

    It "TestStartStopMaintenanceModeUnitNode" -Skip:$('TestStartStopMaintenanceModeUnitNode' -in $global:SkippedTests) {
        $global:TestName = 'TestStartStopMaintenanceModeUnitNode'

        $ScaleUnitNodes = Get-AzsScaleUnitNode -ResourceGroupName $global:ResourceGroupName -Location $global:Location
        foreach ($ScaleUnitNode in $ScaleUnitNodes) {
            {
                Disable-AzsScaleUnitNode -ResourceGroupName $global:ResourceGroupName -Location $global:Location -Name $ScaleUnitNode.Name -Force -ErrorAction Stop
                Enable-AzsScaleUnitNode -ResourceGroupName $global:ResourceGroupName -Location $global:Location -Name $ScaleUnitNode.Name -Force -ErrorAction Stop
            } | Should Not Throw
            break
        }
    }

    # Tenant VM
    It "TestGetScaleUnitNodeOnTenantVM" -Skip:$('TestGetScaleUnitNodeOnTenantVM' -in $global:SkippedTests) {
        $global:TestName = 'TestGetAllScaleUnitNodes'

        { Get-AzsScaleUnitNode -ResourceGroupName $global:ResourceGroupName -Location $global:Location -Name $global:TenantVMName -ErrorAction Stop } | Should Throw
    }
}
