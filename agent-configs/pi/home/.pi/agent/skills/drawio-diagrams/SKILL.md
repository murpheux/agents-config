---
name: drawio-diagrams
description: "Create or edit draw.io / diagrams.net (.drawio) architecture diagrams as mxGraph XML with AWS/Azure/GCP/Kubernetes icons, and export them to PNG/SVG/PDF"
---

# draw.io / diagrams.net

Use draw.io when the audience is stakeholders or the diagram needs vendor icons and precise layout. For docs that live next to code, prefer Mermaid (see `architecture-diagrams`).

## File conventions
- Path: `docs/diagrams/<kebab-name>.drawio` (source) + exported `<kebab-name>.drawio.svg` or `.png` next to it. Commit both.
- Prefer **`.drawio.svg` / `.drawio.png` with embedded diagram** (`--embed-diagram`) — renders on GitHub and stays editable in draw.io.
- Write **uncompressed** XML (plain `<mxGraphModel>` inside `<diagram>`), so diffs are reviewable.
- One page per view (`<diagram name="...">`): Context, Containers, Deployment, Network, Data flow.

## Skeleton (valid, minimal)
```xml
<mxfile host="pi" type="device">
  <diagram id="deploy" name="Deployment">
    <mxGraphModel dx="1400" dy="900" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1"
                  fold="1" page="1" pageScale="1" pageWidth="1654" pageHeight="1169" math="0" shadow="0">
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>

        <!-- Container / group: children use parent="vpc" and coordinates relative to it -->
        <mxCell id="vpc" value="VPC 10.0.0.0/16" vertex="1" parent="1"
          style="shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_vpc2;container=1;collapsible=0;recursiveResize=0;html=1;whiteSpace=wrap;fontSize=12;verticalAlign=top;align=left;spacingLeft=30;strokeColor=#8C4FFF;fillColor=none;fontColor=#AAB7B8;dashed=0;">
          <mxGeometry x="200" y="80" width="720" height="400" as="geometry"/>
        </mxCell>

        <!-- AWS service icon -->
        <mxCell id="alb" value="ALB" vertex="1" parent="vpc"
          style="shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.elastic_load_balancing;fillColor=#8C4FFF;strokeColor=#ffffff;gradientColor=none;fontColor=#232F3E;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;aspect=fixed;outlineConnect=0;dashed=0;">
          <mxGeometry x="60" y="160" width="60" height="60" as="geometry"/>
        </mxCell>
        <mxCell id="api" value="ECS service&lt;br&gt;api" vertex="1" parent="vpc"
          style="shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.ecs;fillColor=#ED7100;strokeColor=#ffffff;gradientColor=none;fontColor=#232F3E;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=12;aspect=fixed;outlineConnect=0;dashed=0;">
          <mxGeometry x="320" y="160" width="60" height="60" as="geometry"/>
        </mxCell>

        <!-- Edge -->
        <mxCell id="e1" value="HTTPS :443" edge="1" parent="1" source="alb" target="api"
          style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;endArrow=block;endFill=1;strokeWidth=2;">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

## Rules that keep files valid
- Every cell has a **unique `id`**; `0` is root, `1` is the default layer; `vertex="1"` or `edge="1"`; edges reference existing `source`/`target` ids.
- Children of a container set `parent="<container-id>"` and use coordinates **relative to the container**.
- Escape XML in `value`: `&amp;` `&lt;` `&gt;` `&quot;`; with `html=1` a line break is `&lt;br&gt;`.
- Use a 10 px grid; keep icons 48–78 px (`aspect=fixed`); ≥ 40 px spacing; route edges orthogonally, avoid crossings.
- Validate before export: `xmllint --noout file.drawio` (or `python3 -c "import sys,xml.dom.minidom as m; m.parse(sys.argv[1])" file.drawio`).

## Shape libraries (style keys)
| Vendor | Pattern | Examples |
|---|---|---|
| AWS (aws4) | `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.<svc>` | `ec2`, `lambda`, `ecs`, `eks`, `s3`, `rds`, `dynamodb`, `api_gateway`, `cloudfront`, `route_53`, `sqs`, `sns`, `key_management_service`, `secrets_manager`, `waf`, `cloudwatch_2` |
| AWS groups | `shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.<group>` | `group_aws_cloud_alt`, `group_region`, `group_vpc2`, `group_security_group` (subnets), `group_account` |
| AWS colours | fillColor by category | Compute/Containers `#ED7100`, Storage `#7AA116`, Database `#C925D1`, Networking/Analytics `#8C4FFF`, Security `#DD344C`, App integration/Mgmt `#E7157B` |
| Azure | `image;aspect=fixed;html=1;image=img/lib/azure2/<category>/<Icon>.svg` | `networking/Virtual_Networks.svg`, `compute/Function_Apps.svg`, `databases/SQL_Database.svg`, `security/Key_Vaults.svg` |
| GCP | `shape=mxgraph.gcp2.<icon>` | `compute_engine`, `cloud_run`, `cloud_storage`, `cloud_sql` |
| Kubernetes | `shape=mxgraph.kubernetes.icon;prIcon=<kind>` | `pod`, `deploy`, `svc`, `ing`, `ns`, `node` |
| Generic | `rounded=1;whiteSpace=wrap;html=1;` | services, users (`shape=mxgraph.basic.person` / `shape=umlActor`) |

If a shape renders as an empty box, the library name is wrong — search the shape in draw.io and copy its style (Edit Style) rather than guessing.

## Layout conventions
- Nesting: Cloud → Account → Region → VPC/VNet → AZ → Subnet (public/private) → resources.
- Request path left→right; layers top→bottom (edge → app → data). Numbered labels (`1`, `2`, …) on edges for flows, explained in a legend.
- Mark **trust boundaries** with dashed red containers; label ports/protocols on edges; title + date + legend on every page.
- Home-lab diagrams: subnet `10.10.2.0/24` container, hosts from AGENTS.md §5 with IPs, Swarm nodes grouped.

## Export
```bash
# macOS
/Applications/draw.io.app/Contents/MacOS/draw.io -x -f svg --embed-diagram -o docs/diagrams/x.drawio.svg docs/diagrams/x.drawio
# Linux / WSL (desktop app installed): prefix with xvfb-run -a when headless
drawio -x -f png -s 2 -b 10 -o docs/diagrams/x.png docs/diagrams/x.drawio
# Container alternative
docker run --rm -v "$PWD":/data rlespinasse/drawio-export --format svg --output /data/docs/diagrams/out /data/docs/diagrams
```
Flags: `-x` export, `-f png|svg|pdf|jpg`, `-s` scale, `-b` border, `-t` transparent, `-p <page-index>`, `-a` all pages (pdf), `--embed-diagram` keep editable.
