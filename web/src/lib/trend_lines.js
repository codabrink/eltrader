import * as d3 from 'd3'
import { project } from './util'
import { group } from 'd3'

export default function TrendLines({ svg, data, x, candles }) {
  let {
    frames,
    trend_lines: { top_lines: topLines, bottom_lines: bottomLines },
  } = data

  for (const line of topLines) addPoints(line)
  for (const line of bottomLines) addPoints(line)

  let y = candles.getY()

  let svgTopLines = svg
    .selectAll('.topline')
    .data(topLines)
    .enter()
    .append('line')
    .attr('class', 'topline')
    .attr('x1', (d) => x(d.p1.x))
    .attr('x2', (d) => x(d.p2.x))
    .attr('y1', (d) => y(d.p1.y))
    .attr('y2', (d) => y(d.p2.y))
    .attr('stroke', (d) => 'black')

  let svgBottomLines = svg
    .selectAll('.bottomline')
    .data(bottomLines)
    .enter()
    .append('line')
    .attr('class', 'bottomline')
    .attr('x1', (d) => x(d.p1.x))
    .attr('x2', (d) => x(d.p2.x))
    .attr('y1', (d) => y(d.p1.y))
    .attr('y2', (d) => y(d.p2.y))
    .attr('stroke', (d) => 'black')

  function zoomed({ xz }) {
    svgTopLines.attr('x1', (f) => xz(f.p1.x)).attr('x2', (f) => xz(f.p2.x))
    svgBottomLines.attr('x1', (f) => xz(f.p1.x)).attr('x2', (f) => xz(f.p2.x))
  }

  function zoomend() {
    svgTopLines
      .transition()
      .duration(200)
      .attr('y1', (f) => y(f.p1.y))
      .attr('y2', (f) => y(f.p2.y))
    svgBottomLines
      .transition()
      .duration(200)
      .attr('y1', (f) => y(f.p1.y))
      .attr('y2', (f) => y(f.p2.y))
  }

  return { zoomed, zoomend }
}

function addPoints(line) {
  let p1 = { x: line.frame_index, y: line.point.coordinates[1] }
  let p2 = project(p1, line.angle, 200)
  line.p1 = p1
  line.p2 = p2
}
