import { cross } from 'd3'

const arrowOffset = 0.2

export default function TrendLineCrosses({ svg, data, x, candles }) {
  let {
    trend_lines: { top_lines: topLines, bottom_lines: bottomLines },
  } = data.frames[data.frames.length - 1]

  let y = candles.getY()
  let crosses = []
  for (const line of topLines) crosses = crosses.concat(line.crosses)
  for (const line of bottomLines) crosses = crosses.concat(line.crosses)
  for (const cross of crosses) addXY(cross.open_point)

  let svgCrosses = svg
    .selectAll('.cross')
    .data(crosses)
    .enter()
    .append('circle')
    .attr('class', 'cross')
    .attr('cx', (c) => x(c.open_point.x))
    .attr('cy', (c) => y(c.open_point.y))
    .attr('r', 4)
    .attr('fill', 'white')
    .attr('stroke', 'black')

  let arrows = svg
    .selectAll('.arrow')
    .data(crosses)
    .enter()
    .append('text')
    .attr('x', (c) => x(c.open_point.x + arrowOffset))
    .attr('y', (c) => y(c.open_point.y))
    .attr('dy', '0.35em')
    .text((c) => (c.type === 'reject' || c.type === 'down' ? '↓' : '↑'))

  function zoomed({ xz }) {
    svgCrosses.attr('cx', (c) => xz(c.open_point.x))
    arrows.attr('x', (c) => xz(c.open_point.x + arrowOffset))
  }

  function zoomend() {
    svgCrosses
      .transition()
      .duration(200)
      .attr('cy', (c) => y(c.open_point.y))
    arrows
      .transition()
      .duration(200)
      .attr('y', (c) => y(c.open_point.y))
  }

  return { zoomed, zoomend }
}

function addXY(point) {
  point.x = point.coordinates[0]
  point.y = point.coordinates[1]
}
