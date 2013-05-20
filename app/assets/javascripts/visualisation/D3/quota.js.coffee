class D3.Quota
  w: 50
  h: 40
  r:17
  bkgrnd: "#F2F2F2"
  frgrnd: "#4790B2"

  constructor: (divid) ->
    self = @
    used = $("#"+divid).data().used
    data = [{percentage:used},{percentage:100 - used}]

    vis = d3.select("#"+divid).append("svg")
      .attr("class","piechart")
      .attr("width", @w)
      .attr("height", @h)
      .style("background-color", " #E1F0F8")
      .append("g")
        .attr("transform", "translate(#{@r + 2},#{@r + 2})")

    arc = d3.svg.arc()
      .outerRadius(@r)
      .innerRadius(0)

    pie = d3.layout.pie()
      .sort(null)
      .value((d) -> d.percentage )

    piechart = vis.selectAll(".arc")
      .data(pie([{percentage:100}]))
      .enter()
        .append("path")
          .attr("class", "arc")
          .attr("d", arc)
          .style("fill", @frgrnd)
          .style("stroke", "#CCCCCC")
          .style("stroke-width", 1)
          .each( (d) -> self.current = d )

    piechart = vis.selectAll(".arc")
      .data(pie(data))
      .enter()
        .append("path")
          .attr("class", "arc")
          .attr("d", arc)
          .style("fill", @bkgrnd)
          .style("stroke", "#CCCCCC")
          .style("stroke-width", 1)
          .each( (d) -> self.current = d )
      .transition()
        .duration(500)
        .attrTween("d", (a) ->
          console.log self.current.value, a.value
          tween = d3.interpolate(self.current, a)
          self.current = tween(0)
          console.log tween
          console.log self.current
          (t) ->
            arc tween(t)
        )
