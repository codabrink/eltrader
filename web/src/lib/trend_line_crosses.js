import { cross } from 'd3'

export default function TrendLineCrosses({ svg, data, x, candles }) {
  let {
    trend_lines: { top_lines: topLines, bottom_lines: bottomLines },
  } = data

  let y = candles.getY()
  let crosses = []
  for (const line of topLines) crosses = crosses.concat(line.crosses)
  for (const line of bottomLines) crosses = crosses.concat(line.crosses)
  console.log(crosses)

  let svgCrosses = svg
    .selectAll('.cross')
    .data(crosses)
    .enter()
    .append('text')
    .attr('class', 'cross')
    .attr('x', (c) => x(c.open_point.coordinates[0]))
    .attr('y', (c) => y(c.open_point.coordinates[1]))
    .attr('dy', '.35em')
    .attr('stroke', 'black')
    .text('x')

  function zoomed({ xz }) {
    svgCrosses.attr('x', (c) => xz(c.open_point.coordinates[0]))
  }

  function zoomend() {
    svgCrosses
      .transition()
      .duration(200)
      .attr('y', (c) => y(c.open_point.coordinates[1]))
  }

  return { zoomed, zoomend }
}
