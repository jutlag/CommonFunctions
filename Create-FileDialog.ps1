Function Create-FileDialog{
param(
    [String]$Title = "Please select the Test File",
    [String]$Filter = 'Text (*.txt) | *.txt'
)
process{
        Add-Type -AssemblyName System.Windows.Forms
        $dialog = New-Object System.Windows.Forms.OpenFileDialog
        $dialog.InitialDirectory = $PSScriptRoot
        $dialog.Title = $Title
        $dialog.Filter = $Filter
        $result = $dialog.ShowDialog()

        return $dialog.FileName
    }
}
