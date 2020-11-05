<!DOCTYPE html>
<html>
<html-header title='Statistics'>
</html-header>

<body>
    <page section='Statistics'>

<section>
<h2>Statistics</h2>

<p>
This page collects some statistics from the <service-name> systems.
</p>

<$macro statistic-list /CLOSE>
<table class='statistics'>
    <!--
    <tr><th>Statistic</th>
        <th>Value</th>
    </tr>
-->
<$content>
</table>
</$macro>

<$macro statistic-section /CLOSE name:string/REQUIRED>
<tr>
    <td class='statistics-section' colspan='2'><(name)></td>
</tr>
<$content>
</$macro>

<$macro statistic name:string/REQUIRED value:string/REQUIRED>
<tr>
    <td><(name)></td>
    <td><(value)></td>
</tr>
</$macro>

<h3>JFPatch-as-a-service</h3>

    <statistic-list>
        <statistic-section name='Source code'>
            <!-- calculated with `loc service frontend` on 2020-10-27
                 after renaming .hsc to .html, and removing the codemirror
                 source names.
              -->
            <statistic name="Python files" value="19">
            <statistic name="Python lines of code" value="3081">
            <statistic name="Python lines of comment" value="1049">
            <statistic name="Python FIXME marks" value="14">
            <statistic name="HSC (HTML source) files" value="10">
            <statistic name="HSC (HTML source) lines" value="9130">
            <statistic name="Javascript files" value="7">
            <statistic name="Javascript lines" value="3271">
        </statistic-section>

        <statistic-section name='Test code'>
            <statistic name="Test files" value="0">
        </statistic-section>

        <statistic-section name="Project tracking">
            <!-- As of 2020-10-27 -->
            <statistic name="Tasks ToDo" value="6">
            <statistic name="Tasks Doing" value="3">
            <statistic name="Tasks Closed" value="15">
        </statistic-section>

        <statistic-section name="Source control">
            <!-- As of 2020-10-27 -->
            <statistic name="Commits" value="99">
            <statistic name="Commits per day" value="0.5">
            <statistic name="Pending branches" value="0">
        </statistic-section>

        <statistic-section name="Costs">
            <statistic name="AWS Servers" value="~$35 / month">
        </statistic-section>

    </statistic-list>


</section>

    </page>
</body>
</html>
