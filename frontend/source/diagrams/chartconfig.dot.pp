/* Common configuration for the charts
 *
 * Defines to use:
 *  TITLE  Chart title as a HTML block
 */

    graph [
        label = <<B>TITLE</B>>;
        fontname = "Optima";
        fontsize = 20.0;
        labelloc = t;
    ];

    node [ shape=rect, penwidth=2, fontname="Optima" ];
    graph [ nodesep=0.75 ];
    #graph [ splines=ortho ];
    #graph [concentrate=true];
    edge [ penwidth=2.5, fontname="Optima" ];
